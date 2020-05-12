//
//  TetrisViewController.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  Note: handlePan can be called multiple times before the physics engine updates, causing fallingShape.position.x
//  to be changed several time, without the shape moving on screen.  The contactTest in isFallingShapeContactingOn()
//  seems to use the on-screen position, potentially allowing handlePan to move fallingShape into the edge blocks.
//  I fixed this by preventing handlePan from running consecutively before the render look updates (var renderUpdated).
//

import UIKit
import QuartzCore
import SceneKit

enum ScreenSide: Int {
    case left
    case right
    case top
    case bottom
}

struct Constants {
    static let blockSpacing: CGFloat = 1
    static let blockSize: CGFloat = 0.97 * Constants.blockSpacing  // slightly smaller, to prevent continuous contact detection
    static let backgroundThickness: CGFloat = 0.1
    static let blockThickness: CGFloat = 0.5
    static let cameraDistance: CGFloat = 22
    static let blocksPerBase = 12       // frame dimension
    static let blocksPerSide = 22       // frame dimension
    static let respawnDelay = 0.3       // seconds
    static let fastFallTimeFrame = 0.01 // seconds
    static let fastFallPanThreshold: CGFloat = 30.0  // y-points above which fast drop start
}

class TetrisViewController: UIViewController {
    
    var scnView: SCNView!
    var cameraNode: SCNNode!

    let boardScene = BoardScene()

    var simulationTimer = Timer()
    var panGesture = UIPanGestureRecognizer()
    var isRendererUpdated = false  // use to prevent multiple pan gesture between rederer updates
    var fallingShape: ShapeNode!
    var isShapeFalling = false
    var isFastFalling = false
    var frameTime = 1.0  // seconds, affect speed of shapes dropping
    var savedFrameTime = 1.0  // saved during fast drop
    var panStartLocation: Float = 0.0

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Start of code

    override func viewDidLoad() {
        super.viewDidLoad()
        boardScene.setup()
        setupView()
        setupCamera()
        setupLight()
        
        // add tap gesture to rotate shapes
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnView.addGestureRecognizer(tapGesture)
        
        // add pan gesture to move shapes laterally
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        scnView.addGestureRecognizer(panGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spawnRandomShape()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        simulationTimer.invalidate()  // stop timer
    }

    private func spawnRandomShape() {
        fallingShape = boardScene.spawnRandomShape()
        panStartLocation = fallingShape.position.x
        panGesture.isEnabled = true
        startSimulation()
    }
    
    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: frameTime, target: self,
                                               selector: #selector(updateSimulation),
                                               userInfo: nil, repeats: true)
    }
    
    // execute one simulation step
    @objc func updateSimulation() {
        if !isFallingShapeContactingOn(screenSide: .bottom) {
            // move one space down (handlePan handles moving laterally)
            fallingShape.position.y -= Float(Constants.blockSpacing)
        } else {
            // shape reached bottom, remove rows and re-spawn new shape
            simulationTimer.invalidate()  // restart in spawnRandomShape()
            panGesture.isEnabled = false  // cancel any existing panGesture, so it doesn't carry over to next falling shape
            frameTime = savedFrameTime
            isFastFalling = false
            boardScene.separateBlocksFrom(shapeNode: fallingShape)
            boardScene.removeFullRows()
            spawnRandomShape()
        }
    }
    
    // MARK: - Gesture Recognizers
    
    // rotate falling shape 90 deg CCW when tapped
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        fallingShape.transform = SCNMatrix4Rotate(fallingShape.transform, .pi/2, 0, 0, 1)
    }
    
    // slide shape left or right when panned
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        guard isRendererUpdated else { return }  // don't allow consecutive calls to handlePan between renderer updates
        isRendererUpdated = false
//        print("P", terminator: "")
        guard !isFastFalling else { return }  // don't assess panning, while fast falling
        if recognizer.state == .began {
            panStartLocation = fallingShape.position.x  // units: scene coords
        }
        // Note: While the pan continues, translation continuously provides the screen position
        // relative to the starting point (in points).
        let translation = recognizer.translation(in: scnView)
//        print(translation)
        if abs(translation.x) > abs(translation.y) {
            // pan across, move shape laterally
            var potentialPositionX = panStartLocation + Float(translation.x * Constants.blockSpacing * 17 / view.frame.width)  // empirically derived
            potentialPositionX = (floor(potentialPositionX / Float(Constants.blockSpacing) - 0.5) + 0.5) * Float(Constants.blockSpacing)  // discretize
            if potentialPositionX < fallingShape.position.x {
                if !isFallingShapeContactingOn(screenSide: .left) {
//                    print("moveLeft")
                    fallingShape.position.x -= Float(Constants.blockSpacing)  // just move one position at a time, to avoid overshooting edges
                }
            } else if potentialPositionX > fallingShape.position.x {
                if !isFallingShapeContactingOn(screenSide: .right) {
//                    print("moveRight")
                    fallingShape.position.x += Float(Constants.blockSpacing)
                }
            }
        } else if translation.y > Constants.fastFallPanThreshold {
            // pan down, drop shape fast
            isFastFalling = true
            savedFrameTime = frameTime
            frameTime = Constants.fastFallTimeFrame
            simulationTimer.invalidate()
            startSimulation()
        }
    }
    
    // MARK: - Setup
    
    private func setupView() {
        scnView = self.view as? SCNView
        scnView.showsStatistics = false  // true: show GPU resource usage and frames-per-second along bottom of scene
        scnView.allowsCameraControl = false  // false: move camera programmatically
        scnView.autoenablesDefaultLighting = false  // false: disable default (ambient) light, if another light soure is specified
        scnView.isPlaying = true  // true: prevent SceneKit from entering a "paused" state, if there isn't anything to animate
        scnView.scene = boardScene
        scnView.delegate = self  // needed for renderer, below
    }
    
    private func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, Constants.cameraDistance)
        boardScene.rootNode.addChildNode(cameraNode)
    }
    
    private func setupLight() {
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        boardScene.rootNode.addChildNode(lightNode)

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        boardScene.rootNode.addChildNode(ambientLightNode)
    }
    
    // MARK: - Utility Functions
    
    // determine if any bumpers on the falling shape are contacting another block or edge
    private func isFallingShapeContactingOn(screenSide: ScreenSide) -> Bool {
        var contactingBumper: SCNNode!
        for node in fallingShape.childNodes {
            if let blockNode = node as? BlockNode {
                switch screenSide {
                case .left:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.topBumper
                    case 180:
                        contactingBumper = blockNode.rightBumper
                    case -90:
                        contactingBumper = blockNode.bottomBumper
                    default:
                        contactingBumper = blockNode.leftBumper
                    }
                case .right:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.bottomBumper
                    case 180:
                        contactingBumper = blockNode.leftBumper
                    case -90:
                        contactingBumper = blockNode.topBumper
                    default:
                        contactingBumper = blockNode.rightBumper
                    }
                case .top:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.rightBumper
                    case 180:
                        contactingBumper = blockNode.bottomBumper
                    case -90:
                        contactingBumper = blockNode.leftBumper
                    default:
                        contactingBumper = blockNode.topBumper
                    }
                case .bottom:
                    switch fallingShape.rotationDegrees {
                    case 90:
                        contactingBumper = blockNode.leftBumper
                    case 180:
                        contactingBumper = blockNode.topBumper
                    case -90:
                        contactingBumper = blockNode.rightBumper
                    default:
                        contactingBumper = blockNode.bottomBumper
                    }
                }
                boardScene.physicsWorld.updateCollisionPairs()  // force physics engine to reevalute possible contacts (may not be needed?)
                let contactedNodes = boardScene.physicsWorld.contactTest(with: contactingBumper.physicsBody!, options: nil)
//                print("(\(fallingShape.rotationDegrees)) check \(screenSide), \(contactedNodes.count) contacts")
                for contactedNode in contactedNodes {
                    // disregard bumpers that are contacting other blocks within its own shape
                    if contactedNode.nodeA.parent != fallingShape && contactedNode.nodeB.parent != fallingShape {
//                        print(" <bump \(screenSide)> ")
                        return true
                    }
                }
            }
        }
        return false
    }
}

extension TetrisViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
//        print(".", terminator: "")
        isRendererUpdated = true
    }
}
