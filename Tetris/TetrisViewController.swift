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

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        boardScene.setup()
        setupView()
        setupCamera()
        setupLight()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        boardScene.physicsWorld.contactDelegate = self
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // check what node was tapped, and rotate it
        let location = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            let result = hitResults[0]
            if let parent = result.node.parent {  // parent is the collection of nodes that makes up the tetris shape
                if let parentName = parent.name {
                    print(parentName)
                    parent.transform = SCNMatrix4Rotate(parent.transform, -.pi/2, 0, 0, 1)
                    parent.physicsBody?.resetTransform()  // pws: doesn't enable rotation (rotation doesn't work if blocks are .dynamic)???
                }
            }
        }
    }
    
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
        if let bodyA = contact.nodeA.physicsBody, let bodyB = contact.nodeB.physicsBody {
            let contactMask = bodyA.categoryBitMask | bodyB.categoryBitMask
            if contactMask == (PhysicsCategory.Block | PhysicsCategory.Frame) {
                print("contact block to frame")
                boardScene.rootNode.childNodes.forEach { $0.removeAllActions() }
                contact.nodeA.position.y = round(contact.nodeA.position.y) + 0.09  // correct for overshoot in -y (need to correct other blocks)
            } else if contactMask == PhysicsCategory.Block {
                print("contact block to block")
                boardScene.rootNode.childNodes.forEach { $0.removeAllActions() }  // stop all blocks from moving
//                bodyA.contactTestBitMask = PhysicsCategory.None  // pws: don't need to remove contact bit mask... contacts stop
                contact.nodeA.position.y = round(contact.nodeA.position.y) + 0.09  // correct for overshoot in -y (need to correct other blocks)
                print(contact.nodeA.position, contact.nodeB.position)
            } else if contactMask == PhysicsCategory.Frame {
                print("contact frame to frame")
            }
        }
    }
}
