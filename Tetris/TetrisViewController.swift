//
//  TetrisViewController.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  Note: calls to contactTest (or functions that call contactTest) must be made from the renderer loop.
//  Ealier version of the app called contactTest from a sepatate simulation loop, and from the pan gesture.
//  This resulted in contactTest returning no contacts, when there should be contacts, resulting in shapes
//  moving through other blocks.
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

    var panGesture = UIPanGestureRecognizer()
    var targetPositionX: Float = 0.0
    var fallingShape: ShapeNode!
    var isShapeFalling = false
    var isFastFalling = false
    var spawnTime: TimeInterval = 0
    var frameTime = 1.0  // seconds, affect speed of shapes falling
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

    private func spawnRandomShape() {
        fallingShape = boardScene.spawnRandomShape()
        targetPositionX = fallingShape.position.x  // units: scene coords
        panStartLocation = fallingShape.position.x
        panGesture.isEnabled = true
        isShapeFalling = true
    }
    
    func moveShapeDown() {
        if !isFallingShapeContactingOn(screenSide: .bottom) {
            // move one space down (handlePan handles moving laterally)
            fallingShape.position.y -= Float(Constants.blockSpacing)
        } else {
            // shape reached bottom, remove rows and re-spawn new shape
            panGesture.isEnabled = false  // cancel any existing panGesture, so it doesn't carry over to next falling shape
            isFastFalling = false  // this line must come after disabling panGesture
            isShapeFalling = false
            frameTime = savedFrameTime
            boardScene.separateBlocksFrom(shapeNode: fallingShape)
            boardScene.removeFullRows()
            spawnRandomShape()
        }
    }
    
    func moveShapeAcross() {
        if targetPositionX < fallingShape.position.x {
            if !isFallingShapeContactingOn(screenSide: .left) {
                fallingShape.position.x -= Float(Constants.blockSpacing)  // just move one position at a time, to avoid overshooting edges
            } else {
                targetPositionX = fallingShape.position.x
            }
        } else if targetPositionX > fallingShape.position.x {
            if !isFallingShapeContactingOn(screenSide: .right) {
                fallingShape.position.x += Float(Constants.blockSpacing)
            } else {
                targetPositionX = fallingShape.position.x
            }
        }
    }
    
    // MARK: - Gesture Recognizers
    
    // rotate falling shape 90 deg CCW when tapped
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        fallingShape.transform = SCNMatrix4Rotate(fallingShape.transform, .pi/2, 0, 0, 1)
    }
    
    // move shape left/right when panning across, or fast down when panning down
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        guard !isFastFalling else { return }  // don't assess panning, while fast falling
        if recognizer.state == .began {
            panStartLocation = fallingShape.position.x  // units: scene coords
        }
        // Note: While the pan continues, translation continuously provides the screen position relative to the starting point (in points).
        let translation = recognizer.translation(in: scnView)
        if abs(translation.x) > abs(translation.y) {
            // pan across, move shape laterally (actual move is in renderer)
            DispatchQueue.main.async {
                self.targetPositionX = self.panStartLocation + Float(translation.x * Constants.blockSpacing * 17 / self.view.frame.width)  // empirically derived
                self.targetPositionX = (floor(self.targetPositionX / Float(Constants.blockSpacing) - 0.5) + 0.5) * Float(Constants.blockSpacing)  // discretize
            }
        } else if translation.y > Constants.fastFallPanThreshold {
            // pan down, drop shape fast
            isFastFalling = true
            savedFrameTime = frameTime
            spawnTime = 0  // force immediate start of dropping in renderer
            frameTime = Constants.fastFallTimeFrame
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
                for contactedNode in contactedNodes {
                    // disregard bumpers that are contacting other blocks within its own shape
                    if contactedNode.nodeA.parent != fallingShape && contactedNode.nodeB.parent != fallingShape {
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
        if isShapeFalling {
            if time > spawnTime {
                spawnTime = time + frameTime
                moveShapeDown()
            }
        }
        moveShapeAcross()
    }
}
