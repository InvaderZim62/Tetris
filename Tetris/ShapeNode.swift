//
//  ShapeNode.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  ShapeTypes              ◻️             ◻️     ◻️◻️       ◻️◻️      ◻️       ◻️◻️
//         I: ◻️◻️◻️◻️  J: ◻️◻️◻️  L: ◻️◻️◻️  O: ◻️◻️  S: ◻️◻️   T: ◻️◻️◻️  Z:   ◻️◻️
//    origin:    ^            ^           ^        ^           ^         ^          ^
//

import UIKit
import SceneKit

enum ShapeType: Int {
    case I
    case J
    case L
    case O
    case S
    case T
    case Z
    
    static func random() -> ShapeType {
        let maxValue = Z.rawValue
        let rand = arc4random_uniform(UInt32(maxValue + 1))
        return ShapeType(rawValue: Int(rand))!
    }
}

class ShapeNode: SCNNode {  // ShapeNode is the parent node of blocks that make a Tetris shape
    
    var type = ShapeType.L
    var scaleFactor: CGFloat = 1
    
    var rotationDegrees: Int {
        return Int(round(eulerAngles.z * 180 / .pi))
    }
    
    init(type: ShapeType, scaleFactor: CGFloat = 1) {
        self.type = type
        self.scaleFactor = scaleFactor
        super.init()
        name = "Shape Node"
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        let size = Constants.blockSpacing * scaleFactor
        switch type {
        case .I:
            addBlockNode(position: SCNVector3( -size,    0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(  size,    0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(2*size,    0, 0), color: .cyan)
        case .J:
            addBlockNode(position: SCNVector3( -size,    0, 0), color: .blue)
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .blue)
            addBlockNode(position: SCNVector3(  size,    0, 0), color: .blue)
            addBlockNode(position: SCNVector3( -size, size, 0), color: .blue)
        case .L:
            addBlockNode(position: SCNVector3( -size,    0, 0), color: .orange)
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .orange)
            addBlockNode(position: SCNVector3(  size,    0, 0), color: .orange)
            addBlockNode(position: SCNVector3(  size, size, 0), color: .orange)
        case .O:
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(  size,    0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(     0, size, 0), color: .yellow)
            addBlockNode(position: SCNVector3(  size, size, 0), color: .yellow)
        case .S:
            addBlockNode(position: SCNVector3( -size,    0, 0), color: .green)
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .green)
            addBlockNode(position: SCNVector3(     0, size, 0), color: .green)
            addBlockNode(position: SCNVector3(  size, size, 0), color: .green)
        case .T:
            addBlockNode(position: SCNVector3( -size,    0, 0), color: .purple)
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .purple)
            addBlockNode(position: SCNVector3(  size,    0, 0), color: .purple)
            addBlockNode(position: SCNVector3(     0, size, 0), color: .purple)
        case .Z:
            addBlockNode(position: SCNVector3(     0,    0, 0), color: .red)
            addBlockNode(position: SCNVector3(  size,    0, 0), color: .red)
            addBlockNode(position: SCNVector3( -size, size, 0), color: .red)
            addBlockNode(position: SCNVector3(     0, size, 0), color: .red)
        }
    }
    
    private func addBlockNode(position: SCNVector3, color: UIColor) {
        let blockNode = BlockNode(color: color, scaleFactor: scaleFactor)
        blockNode.position = position
        addChildNode(blockNode)
    }
}
