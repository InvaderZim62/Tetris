//
//  BlockNode.swift
//  Tetris
//
//  Created by Phil Stern on 5/8/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import UIKit
import SceneKit

struct BlockConstants {
    static let bumperDistanceFactor: CGFloat = 0.8  // * blockSpacing
}

class BlockNode: SCNNode {

    enum BlockSide: Int {
        case left
        case right
        case top
        case bottom
    }

    var leftBumper: SCNNode!
    var rightBumper: SCNNode!
    var topBumper: SCNNode!
    var bottomBumper: SCNNode!
    
    init(color: UIColor) {
        super.init()
        name = "Block Node"
        geometry = SCNBox(width: Constants.blockSize,
                          height: Constants.blockSize,
                          length: Constants.blockThickness,
                          chamferRadius: 0.1 * Constants.blockSize)
        geometry?.firstMaterial?.diffuse.contents = color
        physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        addBumpers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func addBumpers() {
        leftBumper = addBumperTo(side: .left)
        rightBumper = addBumperTo(side: .right)
        topBumper = addBumperTo(side: .top)
        bottomBumper = addBumperTo(side: .bottom)
    }
    
    private func addBumperTo(side: BlockSide) -> SCNNode {
        let bumper = SCNSphere(radius: 0.1)
        bumper.firstMaterial?.diffuse.contents = UIColor.clear
        let bumperNode = SCNNode(geometry: bumper)
        switch side {
        case .left:
            bumperNode.position = SCNVector3(-BlockConstants.bumperDistanceFactor * Constants.blockSpacing, 0, 0)
        case .right:
            bumperNode.position = SCNVector3(BlockConstants.bumperDistanceFactor * Constants.blockSpacing, 0, 0)
        case .top:
            bumperNode.position = SCNVector3(0, BlockConstants.bumperDistanceFactor * Constants.blockSpacing, 0)
        case .bottom:
            bumperNode.position = SCNVector3(0, -BlockConstants.bumperDistanceFactor * Constants.blockSpacing, 0)
        }
        bumperNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        bumperNode.name = "Bumper"
        addChildNode(bumperNode)
        return bumperNode
    }
}
