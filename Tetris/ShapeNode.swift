//
//  ShapeNode.swift
//  Tetris
//
//  Created by Phil Stern on 5/1/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  ShapeTypes            ◻️             ◻️        ◻️◻️       ◻️◻️      ◻️       ◻️◻️
//    Line: ◻️◻️◻️◻️  J: ◻️◻️◻️  L: ◻️◻️◻️  Cube: ◻️◻️  S: ◻️◻️   T: ◻️◻️◻️  Z:   ◻️◻️
//    origin:  ^            ^           ^           ^           ^         ^          ^
//

import UIKit
import SceneKit

enum ShapeType: Int {
    case Line
    case J
    case L
    case Cube
    case S
    case T
    case Z
    
    static func random() -> ShapeType {
        let maxValue = Z.rawValue
        let rand = arc4random_uniform(UInt32(maxValue + 1))
        return ShapeType(rawValue: Int(rand))!
    }
}

class ShapeNode: SCNNode {  // ShapeNode is the parent node of blocks that make a tetris shape
    
    var type = ShapeType.L
    
    var rotationDegrees: Int {
        return Int(round(eulerAngles.z * 180 / .pi))
    }
    
    init(type: ShapeType) {
        self.type = type
        super.init()
        name = "Shape Node"
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        switch type {
        case .Line:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(2*Constants.blockSpacing,                      0, 0), color: .cyan)
        case .J:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .blue)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .blue)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .blue)
            addBlockNode(position: SCNVector3( -Constants.blockSpacing, Constants.blockSpacing, 0), color: .blue)
        case .L:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .orange)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .orange)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .orange)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing, Constants.blockSpacing, 0), color: .orange)
        case .Cube:
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .yellow)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing, Constants.blockSpacing, 0), color: .yellow)
        case .S:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .green)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .green)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .green)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing, Constants.blockSpacing, 0), color: .green)
        case .T:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .purple)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .purple)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .purple)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .purple)
        case .Z:
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .red)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .red)
            addBlockNode(position: SCNVector3( -Constants.blockSpacing, Constants.blockSpacing, 0), color: .red)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .red)
        }
    }
    
    private func addBlockNode(position: SCNVector3, color: UIColor) {
        let blockNode = BlockNode(color: color)
        blockNode.position = position
        addChildNode(blockNode)
    }
}
