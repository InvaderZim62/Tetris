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
    
    var spawnPosition = SCNVector3()

    func setup() {
        background.contents = "Background_Diffuse.png"
        
        physicsWorld.gravity = SCNVector3(0, -3, 0)  // gravity in m/s
        
        // specify positions of block centers
        // origin is center of background, midway through edge blocks
        // x: right (columns), y: up (rows), z: out of screen
        addBackground()
        
        // outer edge blocks (row = col = 0 is lower left corner)
        for row in 0..<Constants.blocksPerSide {
            for col in 0..<Constants.blocksPerBase {
                if row == 0 || row == Constants.blocksPerSide - 1 || col == 0 || col == Constants.blocksPerBase - 1 {
                    _ = addEdgeBlockNode(position: BoardScene.positionFor(row: row, col: col), color: .gray)
                }
            }
        }
        spawnPosition = BoardScene.positionFor(row: Constants.blocksPerSide - 3, col: Constants.blocksPerBase / 2)  // near top center of board
    }
    
    func spawnRandomShape() -> ShapeNode {
        let shapeNode = addShapeNode(type: ShapeType.random(), position: spawnPosition)
        return shapeNode
    }
    
    private func addShapeNode(type: ShapeType, position: SCNVector3) -> ShapeNode {
        let blockNode = ShapeNode(type: type)
        blockNode.position = position
        rootNode.addChildNode(blockNode)
        return blockNode
    }
    
    private func addBackground() {
        let boardWidth = Constants.blockSpacing * CGFloat(Constants.blocksPerBase)
        let boardHeight = Constants.blockSpacing * CGFloat(Constants.blocksPerSide)
        let block = SCNBox(width: boardWidth,
                           height: boardHeight,
                           length: Constants.backgroundThickness,
                           chamferRadius: 0)
        block.firstMaterial?.diffuse.contents = UIColor.black
        let blockNode = SCNNode(geometry: block)
        blockNode.name = "Background"
        blockNode.position = SCNVector3(0, 0, -(Constants.blockThickness + Constants.backgroundThickness) / 2)
        blockNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        rootNode.addChildNode(blockNode)
    }
    
    private func addEdgeBlockNode(position: SCNVector3, color: UIColor) -> SCNNode {
        let block = SCNBox(width: Constants.blockSize,
                           height: Constants.blockSize,
                           length: Constants.blockThickness,
                           chamferRadius: 0.1 * Constants.blockSize)
        block.firstMaterial?.diffuse.contents = color
        let blockNode = SCNNode(geometry: block)
        blockNode.name = "Edge Block"
        blockNode.position = position
        blockNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        blockNode.physicsBody?.categoryBitMask = PhysicsCategory.Frame
        blockNode.physicsBody?.contactTestBitMask = PhysicsCategory.Block | PhysicsCategory.Frame  // pws: may not need this (added to blocks)
        rootNode.addChildNode(blockNode)
        return blockNode
    }

    // return position in scene coordinates (origin in center of boardScene)
    // from row, col (origin in lower left corner)
    static func positionFor(row: Int, col: Int) -> SCNVector3 {
        let rowOffset = CGFloat(Constants.blocksPerSide) / 2 - 0.5
        let colOffset = CGFloat(Constants.blocksPerBase) / 2 - 0.5
        return SCNVector3((CGFloat(col) - colOffset) * Constants.blockSpacing,
                          (CGFloat(row) - rowOffset) * Constants.blockSpacing,
                          0)
    }
}
