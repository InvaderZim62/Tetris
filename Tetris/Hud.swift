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

    var isGameOver = false {
        didSet {
            if isGameOver { gameOverLabel.text = "Game Over" }
        }
    }
    var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }

    let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let gameOverLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    func setup() {
        scoreLabel.position = CGPoint(x: 0.2 * frame.width, y: 0.92 * frame.height)
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
        score = 0

        gameOverLabel.position = CGPoint(x: frame.midX, y: 0.5 * frame.height)
        gameOverLabel.fontSize = 30
        addChild(gameOverLabel)
    }
}
