//
//  Hud.swift
//  Othello
//
//  Created by Phil Stern on 4/23/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import Foundation
import SpriteKit

class Hud: SKScene, ButtonDelegate {
    
    var newGameButton: Button!

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
            if isGameOver {
                gameOverLabel.text = "Game Over"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.newGameButton.isUserInteractionEnabled = true
                    self.gameOverLabel.text = "New Game"
                }
            } else {
                gameOverLabel.text = ""
                newGameButton.isUserInteractionEnabled = false
            }
        }
    }

    let levelTextLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let scoreTextLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let gameOverLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    var buttonHandler: (() -> Void)?

    func setup(buttonHandler: @escaping () -> Void) {
        self.buttonHandler = buttonHandler
        
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
        
        // line up button with gameOverLabel (button doesn't have its own text)
        newGameButton = Button(texture: nil, color: .clear, size: CGSize(width: 100, height: 30))
        newGameButton.position = CGPoint(x: frame.midX, y: 0.5 * frame.height)
        newGameButton.delegate = self
        addChild(newGameButton)
        
        isGameOver = false  // must be after initialization of newGameButton
    }
    
    func reset() {
        level = 0
        score = 0
        isGameOver = false
    }
    
    // MARK: - ButtonDelegate
    
    func buttonClicked(sender: Button) {
        buttonHandler?()
    }
}
