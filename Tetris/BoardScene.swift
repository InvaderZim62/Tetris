//
//  BoardScene.swift
//  Sorry3D
//
//  Created by Phil Stern on 4/25/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import UIKit
import SceneKit

class BoardScene: SCNScene {

    func setup() {
        background.contents = "Background_Diffuse.png"
        
        physicsWorld.gravity = SCNVector3(0, -3, 0)  // gravity in m/s
        
        // specify positions of square centers
        // origin is center of background, midway through edge blocks
        // squares[0][0] is lower left corner
        // x: right (columns), y: up (rows), z: out of screen
        addBackground()
        
        // outer edge squares
        for row in 0..<Constants.squaresPerSide {
            for col in 0..<Constants.squaresPerBase {
                if row == 0 || row == Constants.squaresPerSide - 1 || col == 0 || col == Constants.squaresPerBase - 1 {
                    _ = addEdgeSquareNode(position: positionFor(row: row, col: col), color: .gray)
                }
            }
        }
        
        _ = addBlockNode(type: .s, position: SCNVector3(-1.5, 8.5, 0))
        let zBlock = addBlockNode(type: .z, position: SCNVector3(2.5, 5.5, 0))
        _ = addBlockNode(type: .t, position: SCNVector3(0.5, 2.5, 0))
        _ = addBlockNode(type: .cube, position: SCNVector3(-4.5, 3.5, 0))
        
        let moveDown = SCNAction.move(by: SCNVector3(0, -25, 0), duration: 4)  // doesn't stop on contact with blocks or edges
        zBlock.runAction(moveDown)                                             // (all .kinematic), but does rotate when tapped
    }
    
    private func addBlockNode(type: BlockType, position: SCNVector3) -> BlockNode {
        let blockNode = BlockNode(type: type, scene: self)
        blockNode.position = position
        rootNode.addChildNode(blockNode)
        return blockNode
    }
    
    private func addBackground() {
        let boardWidth = Constants.squareSpacing * CGFloat(Constants.squaresPerBase)
        let boardHeight = Constants.squareSpacing * CGFloat(Constants.squaresPerSide)
        let square = SCNBox(width: boardWidth,
                            height: boardHeight,
                            length: Constants.backgroundThickness,
                            chamferRadius: 0)
        square.firstMaterial?.diffuse.contents = UIColor.black
        let squareNode = SCNNode(geometry: square)
        squareNode.name = "Background"
        squareNode.position = SCNVector3(0, 0, -(Constants.squareThickness + Constants.backgroundThickness) / 2)
        squareNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        rootNode.addChildNode(squareNode)
    }
    
    private func addEdgeSquareNode(position: SCNVector3, color: UIColor) -> SCNNode {
        let square = SCNBox(width: Constants.squareSize,
                            height: Constants.squareSize,
                            length: Constants.squareThickness,
                            chamferRadius: 0.1 * Constants.squareSize)
        square.firstMaterial?.diffuse.contents = color
        let squareNode = SCNNode(geometry: square)
        squareNode.name = "Edge Square"
        squareNode.position = position
        squareNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        squareNode.physicsBody?.categoryBitMask = PhysicsCategory.Frame
        squareNode.physicsBody?.contactTestBitMask = PhysicsCategory.Block | PhysicsCategory.Frame  // pws: may not need this (added to blocks)
        rootNode.addChildNode(squareNode)
        return squareNode
    }

    private func positionFor(row: Int, col: Int) -> SCNVector3 {
        let rowOffset = CGFloat(Constants.squaresPerSide) / 2 - 0.5  // middle of board is origin
        let colOffset = CGFloat(Constants.squaresPerBase) / 2 - 0.5  // middle of board is origin
        return SCNVector3((CGFloat(col) - colOffset) * Constants.squareSpacing,
                          (CGFloat(row) - rowOffset) * Constants.squareSpacing,
                          0)
    }
}
