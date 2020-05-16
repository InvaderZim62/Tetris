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

    var score = 0 {
        didSet {
            scoreLabel.text = "\(score)"
        }
    }

    let scoreLabel = SKLabelNode(fontNamed: "Menlo-Bold")

    func setup() {
        scoreLabel.position = CGPoint(x: frame.midX, y: 0.95 * frame.height)
        scoreLabel.fontSize = 20
        addChild(scoreLabel)
        score = 0
    }
}
