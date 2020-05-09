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

struct PhysicsCategory {
    static let None: Int = 0
    static let Block: Int = 1 << 0
    static let Frame: Int = 1 << 1
}

class TetrisViewController: UIViewController, SCNPhysicsContactDelegate {
    
    var scnView: SCNView!
    var cameraNode: SCNNode!

    let boardScene = BoardScene()
    
    var fallingShape: ShapeNode!
    var isShapeFalling = false
    var fallDuration = 10.0  // seconds
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

        boardScene.physicsWorld.contactDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        spawnRandomShape()
    }
    
    // rotate falling shape 90 deg CCW when tapped
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        fallingShape.transform = SCNMatrix4Rotate(fallingShape.transform, .pi/2, 0, 0, 1)
    }
        
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            panStartLocation = fallingShape.position.x  // units: scene coords
        }
        let translation = recognizer.translation(in: scnView)  // units: screen points
        fallingShape.position.x = panStartLocation + Float(translation.x * 17 / view.frame.width)  // empirically derived
        fallingShape.position.x = round(fallingShape.position.x) + 0.5
        
        // limit position laterally to stay within board edges (doesn't work when shape is rotated)
        let leftBoardEdge = BoardScene.positionFor(row: 0, col: 0)
        let minShapePositionX = leftBoardEdge.x - Float(fallingShape.type.xRange().min) + 1
        let rightBoardEdge = BoardScene.positionFor(row: 0, col: Constants.blocksPerBase)
        let maxShapePositionX = rightBoardEdge.x - Float(fallingShape.type.xRange().max) - 2
        fallingShape.position.x = max(min(fallingShape.position.x, maxShapePositionX), minShapePositionX)
    }
    
    private func spawnRandomShape() {
        fallingShape = boardScene.spawnRandomShape()
        let moveDown = SCNAction.move(by: SCNVector3(0, -25, 0), duration: fallDuration)
        fallingShape.runAction(moveDown)
        isShapeFalling = true
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
    
    // MARK: - SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        fallingShape.removeAllActions()  // stop shape from falling
        isShapeFalling = false
        // contacts come in groups, wait until all are done, then spawn new shape once
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.respawnDelay) {
            if !self.isShapeFalling {
                self.spawnRandomShape()  // this sets isShapeFalling = true
                print("------------")
            }
        }

        // pws: temp code for debugging
        if let bodyA = contact.nodeA.physicsBody, let bodyB = contact.nodeB.physicsBody {
            let contactMask = bodyA.categoryBitMask | bodyB.categoryBitMask
            if contactMask == (PhysicsCategory.Block | PhysicsCategory.Frame) {
                print("\ncontact block to frame")
            } else if contactMask == PhysicsCategory.Block {
                print("\ncontact block to block")
            } else if contactMask == PhysicsCategory.Frame {
                print("contact frame to frame")
            } else {
                print("contact undefined")
            }
        }
        
        print(contact.nodeA.parent?.name ?? "", contact.nodeA.name!, contact.nodeA.worldPosition)
        print(contact.nodeB.parent?.name ?? "", contact.nodeB.name!, contact.nodeB.worldPosition)
        print("contact pt.: ", contact.contactPoint)
        
        let worldPositionA = contact.nodeA.worldPosition
        let worldPositionB = contact.nodeB.worldPosition
        let contactAngle = atan2(worldPositionB.y - worldPositionA.y, worldPositionB.x - worldPositionA.x) * 57.3
        print("contact angle: \(contactAngle)")
    }
}
