//
//  TetrisViewController.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
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
}

class TetrisViewController: UIViewController {
    
    var scnView: SCNView!
    var cameraNode: SCNNode!

    let boardScene = BoardScene()

    var simulationTimer = Timer()
    var fallingShape: ShapeNode!
    var isShapeFalling = false
    var frameTime = 0.3  // seconds
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
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        scnView.addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
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
        isShapeFalling = true
        startSimulation()
    }
    
    private func startSimulation() {
        simulationTimer = Timer.scheduledTimer(timeInterval: frameTime, target: self,
                                               selector: #selector(updateSimulation),
                                               userInfo: nil, repeats: true)
    }
    
    // execute one simulation step
    // move falling shape, if not blocked by bottom edge or another shape
    @objc func updateSimulation() {
        boardScene.physicsWorld.updateCollisionPairs()  // force physics engine to reevalute possible contacts
        if !isFallingShapeContactingOn(screenSide: .bottom) {
            fallingShape.position.y -= Float(Constants.blockSpacing)
        } else {
            simulationTimer.invalidate()
            spawnRandomShape()
        }
    }
    
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
                let contactingNodes = boardScene.physicsWorld.contactTest(with: contactingBumper.physicsBody!, options: nil)
                for contactingNode in contactingNodes {
                    // disregard bumpers that are contacting other blocks within its own shape
                    if contactingNode.nodeA.parent != fallingShape && contactingNode.nodeB.parent != fallingShape {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // MARK: - Gesture Recognizers
    
    // rotate falling shape 90 deg CCW when tapped
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        fallingShape.transform = SCNMatrix4Rotate(fallingShape.transform, .pi/2, 0, 0, 1)
    }
        
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            panStartLocation = fallingShape.position.x  // units: scene coords
        }
        let translation = recognizer.translation(in: scnView)  // units: screen points  // pws: limit this to prevent moving too fast (going through blocks)
        var potentialPositionX = panStartLocation + Float(translation.x * 17 / view.frame.width)  // empirically derived
        potentialPositionX = round(potentialPositionX) + 0.5  // pws: assumes blockSpacing = 1 (fix use of round)
        if potentialPositionX < fallingShape.position.x {
            if !isFallingShapeContactingOn(screenSide: .left) {
                fallingShape.position.x = potentialPositionX
            }
        } else if potentialPositionX > fallingShape.position.x {
            if !isFallingShapeContactingOn(screenSide: .right) {
                fallingShape.position.x = potentialPositionX
            }
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
}
