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
        name = "Shape Node"
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
        
    var rotationDegrees: Int {
        return Int(eulerAngles.z * 180 / .pi)
    }

    func setup() {
        switch type {
        case .line:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .cyan)
            addBlockNode(position: SCNVector3(2*Constants.blockSpacing,                      0, 0), color: .cyan)
        case .leftL:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .blue)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .blue)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .blue)
            addBlockNode(position: SCNVector3( -Constants.blockSpacing, Constants.blockSpacing, 0), color: .blue)
        case .rightL:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .orange)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .orange)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .orange)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing, Constants.blockSpacing, 0), color: .orange)
        case .cube:
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .yellow)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .yellow)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing, Constants.blockSpacing, 0), color: .yellow)
        case .s:
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .green)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .green)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .green)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing, Constants.blockSpacing, 0), color: .green)
        case .t:
            addBlockNode(position: SCNVector3( -Constants.blockSpacing,                      0, 0), color: .purple)
            addBlockNode(position: SCNVector3(                       0,                      0, 0), color: .purple)
            addBlockNode(position: SCNVector3(  Constants.blockSpacing,                      0, 0), color: .purple)
            addBlockNode(position: SCNVector3(                       0, Constants.blockSpacing, 0), color: .purple)
        case .z:
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
