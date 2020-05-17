//
//  Hud.swift
//  Othello
//
//  Created by Phil Stern on 4/23/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import Foundation
import SpriteKit

class Hud: SKScene {

    var level = 0 {
        didSet {
            levelLabel.text = "\(level)"
        }
    }
    var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }
    var isGameOver = false {
        didSet {
            if isGameOver { gameOverLabel.text = "Game Over" }
        }
    }

    let levelTextLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let scoreTextLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let gameOverLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    func setup() {
        levelTextLabel.text = "LV"
        levelTextLabel.position = CGPoint(x: 0.16 * frame.width, y: 0.945 * frame.height)
        levelTextLabel.fontSize = 20
        addChild(levelTextLabel)
        
        levelLabel.position = CGPoint(x: 0.16 * frame.width, y: 0.906 * frame.height)
        levelLabel.fontSize = 20
        addChild(levelLabel)
        level = 0

        scoreTextLabel.text = "SCORE"
        scoreTextLabel.position = CGPoint(x: 0.5 * frame.width, y: 0.95 * frame.height)
        scoreTextLabel.fontSize = 20
        addChild(scoreTextLabel)
        
        scoreLabel.position = CGPoint(x: 0.5 * frame.width, y: 0.905 * frame.height)
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
        score = 0

        gameOverLabel.position = CGPoint(x: frame.midX, y: 0.5 * frame.height)
        gameOverLabel.fontSize = 30
        addChild(gameOverLabel)
    }
}
