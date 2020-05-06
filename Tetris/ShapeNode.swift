//
//  ShapeNode.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import UIKit
import SceneKit

enum ShapeType: Int {
    case line
    case leftL
    case rightL
    case cube
    case s
    case t
    case z
    
    static func random() -> ShapeType {
        let maxValue = z.rawValue
        let rand = arc4random_uniform(UInt32(maxValue + 1))
        return ShapeType(rawValue: Int(rand))!
    }
}

class ShapeNode: SCNNode {  // ShapeNode is the parent node of blocks that make a tetris shape
    
    var type = ShapeType.rightL
    
    init(type: ShapeType) {
        self.type = type
        super.init()
        name = "\(type)"
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        switch type {
        case .line:
            addBlockNode(position: SCNVector3(-1, 0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(0, 0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(1, 0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(2, 0, 0), color: .cyan)
        case .leftL:
            addBlockNode(position: SCNVector3(-1, 0, 0), color: .blue)
            addBlockNode(position: SCNVector3(0, 0, 0), color: .blue)
            addBlockNode(position: SCNVector3(1, 0, 0), color: .blue)
            addBlockNode(position: SCNVector3(-1, 1, 0), color: .blue)
        case .rightL:
            addBlockNode(position: SCNVector3(-1, 0, 0), color: .orange)
            addBlockNode(position: SCNVector3(0, 0, 0), color: .orange)
            addBlockNode(position: SCNVector3(1, 0, 0), color: .orange)
            addBlockNode(position: SCNVector3(1, 1, 0), color: .orange)
        case .cube:
            addBlockNode(position: SCNVector3(0, 0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(1, 0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(0, 1, 0), color: .yellow)
            addBlockNode(position: SCNVector3(1, 1, 0), color: .yellow)
        case .s:
            addBlockNode(position: SCNVector3(-1, 0, 0), color: .green)
            addBlockNode(position: SCNVector3(0, 0, 0), color: .green)
            addBlockNode(position: SCNVector3(0, 1, 0), color: .green)
            addBlockNode(position: SCNVector3(1, 1, 0), color: .green)
        case .t:
            addBlockNode(position: SCNVector3(-1, 0, 0), color: .purple)
            addBlockNode(position: SCNVector3(0, 0, 0), color: .purple)
            addBlockNode(position: SCNVector3(1, 0, 0), color: .purple)
            addBlockNode(position: SCNVector3(0, 1, 0), color: .purple)
        case .z:
            addBlockNode(position: SCNVector3(0, 0, 0), color: .red)
            addBlockNode(position: SCNVector3(1, 0, 0), color: .red)
            addBlockNode(position: SCNVector3(-1, 1, 0), color: .red)
            addBlockNode(position: SCNVector3(0, 1, 0), color: .red)
        }
    }
    
    private func addBlockNode(position: SCNVector3, color: UIColor) {
        let block = SCNBox(width: Constants.blockSize,
                           height: Constants.blockSize,
                           length: Constants.blockThickness,
                           chamferRadius: 0.1 * Constants.blockSize)
        block.firstMaterial?.diffuse.contents = color
        let blockNode = SCNNode(geometry: block)
        blockNode.name = "Block Node"
        blockNode.position = position
        blockNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        blockNode.physicsBody?.categoryBitMask = PhysicsCategory.Block  // must be added to each block of tetris shape
        blockNode.physicsBody?.contactTestBitMask = PhysicsCategory.Block | PhysicsCategory.Frame
        addChildNode(blockNode)
    }
}
