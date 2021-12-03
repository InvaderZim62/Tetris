//
//  Hud.swift
//  Othello
//
//  Created by Phil Stern on 4/23/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  The Hud shows information (level, score, game status) along the top and center of the
//  screen using SKLabelNodes.  The center label switches between being blank and showing
//  "Game Over" (changing to "New Game" after 2 seconds).  An invisible custom button
//  (newGameButton) is aligned with the status label and is enabled when "New Game" is
//  shown.  When the button is pressed, the buttonHandler (passed in) is called.
//
//  A sound selection label is located at the bottom right corner, to allow toggling
//  between sound on and off.  The label is monitored with touchesBegan, rather than using
//  a second custom button.  Touching the label causes the soundSelectionHandler (passed
//  in) to be called.
//
//  A CountdownLabelNode (subclass of SKLabelNode) is also positioned in the center of the
//  screen.  Calling member function showCountdown starts the countdown from any provided
//  number, then hides when done.
//
//  Note: TetrisViewController uses a tap gesture, which is disabled at the end of the
//  game, allowing newGameButton to receive the tap.
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
                gameStatusLabel.text = "Game Over"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.newGameButton.isUserInteractionEnabled = true
                    self.gameStatusLabel.text = "New Game"
                }
            } else {
                gameStatusLabel.text = ""
                newGameButton.isUserInteractionEnabled = false
            }
        }
    }
    var isSoundMuted = false { didSet { soundSelectionLabel.text = isSoundMuted ? "🔇" : "🔈" } }

    let levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let gameStatusLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    let soundSelectionLabel = SKLabelNode()
    let countdownLabel = CountdownLabelNode(fontNamed: "Menlo-Bold")
    var buttonHandler: (() -> Void)?
    var soundSelectionHandler: ((Bool) -> Void)?

    func setup(buttonHandler: @escaping () -> Void, soundSelectionHandler: @escaping (Bool) -> Void) {
        self.buttonHandler = buttonHandler
        self.soundSelectionHandler = soundSelectionHandler
        
        countdownLabel.position = CGPoint(x: frame.midX, y: 0.5 * frame.height)  // middle of screen
        countdownLabel.fontSize = 100
        countdownLabel.fontColor = .red
        addChild(countdownLabel)
        
        let levelTextLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        levelTextLabel.text = "LV"
        levelTextLabel.position = CGPoint(x: 0.16 * frame.width, y: 0.945 * frame.height)  // top left
        levelTextLabel.fontSize = 20
        addChild(levelTextLabel)
        
        levelLabel.position = CGPoint(x: 0.16 * frame.width, y: 0.906 * frame.height)  // top left (below "LV")
        levelLabel.fontSize = 20
        addChild(levelLabel)
        level = 0

        let scoreTextLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        scoreTextLabel.text = "SCORE"
        scoreTextLabel.position = CGPoint(x: frame.midX, y: 0.95 * frame.height)  // top middle
        scoreTextLabel.fontSize = 20
        addChild(scoreTextLabel)
        
        scoreLabel.position = CGPoint(x: 0.5 * frame.width, y: 0.905 * frame.height)  // top middle (below "SCORE")
        scoreLabel.fontSize = 24
        addChild(scoreLabel)
        score = 0

        gameStatusLabel.position = CGPoint(x: frame.midX, y: 0.5 * frame.height)  // middle of screen
        gameStatusLabel.fontSize = 30
        addChild(gameStatusLabel)
        
        // line up button with gameStatusLabel (button doesn't have its own text)
        newGameButton = Button(texture: nil, color: .clear, size: CGSize(width: 100, height: 30))
        newGameButton.position = CGPoint(x: frame.midX, y: 0.5 * frame.height)
        newGameButton.delegate = self
        addChild(newGameButton)
        
        isGameOver = false  // must be after initialization of newGameButton, since it causes newGameButton.isUserInteractionEnabled to be set above
        
        soundSelectionLabel.position = CGPoint(x: 0.92 * frame.width, y: 0.04 * frame.height)  // bottom right
        soundSelectionLabel.fontSize = 20
        addChild(soundSelectionLabel)
        isSoundMuted = false
    }
    
    func reset() {
        level = 0
        score = 0
        isGameOver = false
    }
    
    func showCountdown(from count: Int, completionHandler: @escaping () -> Void) {
        countdownLabel.showCountdown(from: count, completionHandler: completionHandler)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        if soundSelectionLabel.contains(location) {
            isSoundMuted = !isSoundMuted
            soundSelectionHandler?(isSoundMuted)
        }
    }

    // MARK: - ButtonDelegate
    
    func buttonClicked(sender: Button) {
        buttonHandler?()
    }
}
