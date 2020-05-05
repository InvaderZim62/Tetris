//
//  BlockNode.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import UIKit
import SceneKit

enum BlockType {
    case line
    case leftL
    case rightL
    case cube
    case s
    case t
    case z
}

class BlockNode: SCNNode {  // BlockNode is the parent node of blocks that make a tetris shape
    
    var scene: SCNScene!
    var type = BlockType.rightL
    
    init(type: BlockType, scene: SCNScene) {  // pass parent scene, to add joint behaviors to it
        self.type = type
        self.scene = scene
        super.init()
        name = "\(type)"
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        var joint1 = SCNPhysicsHingeJoint()
        var joint2 = SCNPhysicsHingeJoint()
        var joint3 = SCNPhysicsHingeJoint()
        switch type {
        case .line:
            let block1 = addSquareNode(position: SCNVector3(-1, 0, 0), color: .cyan)
            let block2 = addSquareNode(position: SCNVector3(0, 0, 0), color: .cyan)
            let block3 = addSquareNode(position: SCNVector3(1, 0, 0), color: .cyan)
            let block4 = addSquareNode(position: SCNVector3(2, 0, 0), color: .cyan)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block2, right: block3)
            joint3 = makeJoint(left: block3, right: block4)
        case .leftL:
            let block1 = addSquareNode(position: SCNVector3(-1, 0, 0), color: .blue)
            let block2 = addSquareNode(position: SCNVector3(0, 0, 0), color: .blue)
            let block3 = addSquareNode(position: SCNVector3(1, 0, 0), color: .blue)
            let block4 = addSquareNode(position: SCNVector3(-1, 1, 0), color: .blue)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block2, right: block3)
            joint3 = makeJoint(top: block4, bottom: block1)
        case .rightL:
            let block1 = addSquareNode(position: SCNVector3(-1, 0, 0), color: .orange)
            let block2 = addSquareNode(position: SCNVector3(0, 0, 0), color: .orange)
            let block3 = addSquareNode(position: SCNVector3(1, 0, 0), color: .orange)
            let block4 = addSquareNode(position: SCNVector3(1, 1, 0), color: .orange)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block2, right: block3)
            joint3 = makeJoint(top: block4, bottom: block3)
        case .cube:
            let block1 = addSquareNode(position: SCNVector3(0, 0, 0), color: .yellow)
            let block2 = addSquareNode(position: SCNVector3(1, 0, 0), color: .yellow)
            let block3 = addSquareNode(position: SCNVector3(0, 1, 0), color: .yellow)
            let block4 = addSquareNode(position: SCNVector3(1, 1, 0), color: .yellow)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block3, right: block4)
            joint3 = makeJoint(top: block3, bottom: block1)
        case .s:
            let block1 = addSquareNode(position: SCNVector3(-1, 0, 0), color: .green)
            let block2 = addSquareNode(position: SCNVector3(0, 0, 0), color: .green)
            let block3 = addSquareNode(position: SCNVector3(0, 1, 0), color: .green)
            let block4 = addSquareNode(position: SCNVector3(1, 1, 0), color: .green)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block3, right: block4)
            joint3 = makeJoint(top: block3, bottom: block2)
        case .t:
            let block1 = addSquareNode(position: SCNVector3(-1, 0, 0), color: .purple)
            let block2 = addSquareNode(position: SCNVector3(0, 0, 0), color: .purple)
            let block3 = addSquareNode(position: SCNVector3(1, 0, 0), color: .purple)
            let block4 = addSquareNode(position: SCNVector3(0, 1, 0), color: .purple)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block2, right: block3)
            joint3 = makeJoint(top: block4, bottom: block2)
        case .z:
            let block1 = addSquareNode(position: SCNVector3(0, 0, 0), color: .red)
            let block2 = addSquareNode(position: SCNVector3(1, 0, 0), color: .red)
            let block3 = addSquareNode(position: SCNVector3(-1, 1, 0), color: .red)
            let block4 = addSquareNode(position: SCNVector3(0, 1, 0), color: .red)
            joint1 = makeJoint(left: block1, right: block2)
            joint2 = makeJoint(left: block3, right: block4)
            joint3 = makeJoint(top: block4, bottom: block1)
        }
        scene.physicsWorld.addBehavior(joint1)
        scene.physicsWorld.addBehavior(joint2)
        scene.physicsWorld.addBehavior(joint3)
    }
    
    private func addSquareNode(position: SCNVector3, color: UIColor) -> SCNNode {
        let block = SCNBox(width: Constants.squareSize,
                           height: Constants.squareSize,
                           length: Constants.squareThickness,
                           chamferRadius: 0.1 * Constants.squareSize)
        block.firstMaterial?.diffuse.contents = color
        let blockNode = SCNNode(geometry: block)
        blockNode.name = "Block Node"
        blockNode.position = position
        blockNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        blockNode.physicsBody?.isAffectedByGravity = true  // gravity magnitude set in BoardScene
//        blockNode.physicsBody?.velocity = SCNVector3(0, -4, 0)  // initial velocity
        blockNode.physicsBody?.angularDamping = 1
        blockNode.physicsBody?.friction = 1
        blockNode.physicsBody?.damping = 0
        blockNode.physicsBody?.restitution = 0  // bounciness
        addChildNode(blockNode)
        return blockNode
    }
    
    private func makeJoint(left: SCNNode, right: SCNNode) -> SCNPhysicsHingeJoint {
        return SCNPhysicsHingeJoint(bodyA: left.physicsBody!, axisA: SCNVector3(0, 0, 1), anchorA: SCNVector3(0.5, 0, 0),
                                    bodyB: right.physicsBody!, axisB: SCNVector3(0, 0, 1), anchorB: SCNVector3(-0.5, 0, 0))
    }
    
    private func makeJoint(top: SCNNode, bottom: SCNNode) -> SCNPhysicsHingeJoint {
        return SCNPhysicsHingeJoint(bodyA: top.physicsBody!, axisA: SCNVector3(0, 0, 1), anchorA: SCNVector3(0, -0.5, 0),
                                    bodyB: bottom.physicsBody!, axisB: SCNVector3(0, 0, 1), anchorB: SCNVector3(0, 0.5, 0))
    }
}
