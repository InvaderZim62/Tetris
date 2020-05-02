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

class BlockNode: SCNNode {
    
    var type = BlockType.rightL
    var shapeName = "rightL"
    
    init(type: BlockType) {
        self.type = type
        super.init()
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        switch type {
        case .line:
            addSquareNode(position: SCNVector3(-1, 0, 0), color: .cyan)
            addSquareNode(position: SCNVector3(0, 0, 0), color: .cyan)
            addSquareNode(position: SCNVector3(1, 0, 0), color: .cyan)
            addSquareNode(position: SCNVector3(2, 0, 0), color: .cyan)
        case .leftL:
            addSquareNode(position: SCNVector3(-1, 0, 0), color: .blue)
            addSquareNode(position: SCNVector3(0, 0, 0), color: .blue)
            addSquareNode(position: SCNVector3(1, 0, 0), color: .blue)
            addSquareNode(position: SCNVector3(-1, 1, 0), color: .blue)
        case .rightL:
            addSquareNode(position: SCNVector3(-1, 0, 0), color: .orange)
            addSquareNode(position: SCNVector3(0, 0, 0), color: .orange)
            addSquareNode(position: SCNVector3(1, 0, 0), color: .orange)
            addSquareNode(position: SCNVector3(1, 1, 0), color: .orange)
        case .cube:
            addSquareNode(position: SCNVector3(0, 0, 0), color: .yellow)
            addSquareNode(position: SCNVector3(1, 0, 0), color: .yellow)
            addSquareNode(position: SCNVector3(0, 1, 0), color: .yellow)
            addSquareNode(position: SCNVector3(1, 1, 0), color: .yellow)
        case .s:
            addSquareNode(position: SCNVector3(-1, 0, 0), color: .green)
            addSquareNode(position: SCNVector3(0, 0, 0), color: .green)
            addSquareNode(position: SCNVector3(0, 1, 0), color: .green)
            addSquareNode(position: SCNVector3(1, 1, 0), color: .green)
        case .t:
            addSquareNode(position: SCNVector3(-1, 0, 0), color: .purple)
            addSquareNode(position: SCNVector3(0, 0, 0), color: .purple)
            addSquareNode(position: SCNVector3(1, 0, 0), color: .purple)
            addSquareNode(position: SCNVector3(0, 1, 0), color: .purple)
        case .z:
            addSquareNode(position: SCNVector3(0, 0, 0), color: .red)
            addSquareNode(position: SCNVector3(1, 0, 0), color: .red)
            addSquareNode(position: SCNVector3(-1, 1, 0), color: .red)
            addSquareNode(position: SCNVector3(0, 1, 0), color: .red)
        }
    }
    
    func addSquareNode(position: SCNVector3, color: UIColor) {
        let block = SCNBox(width: Constants.squareSize,
                           height: Constants.squareSize,
                           length: Constants.squareThickness,
                           chamferRadius: 0.1 * Constants.squareSize)
        block.firstMaterial?.diffuse.contents = color
        let blockNode = SCNNode(geometry: block)
        blockNode.name = shapeName
        blockNode.position = position
        blockNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        blockNode.physicsBody?.angularDamping = 1
        blockNode.physicsBody?.friction = 1
        blockNode.physicsBody?.restitution = 0  // bounciness
        addChildNode(blockNode)
    }
}
