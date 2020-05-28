//
//  CountdownLabel.swift
//  Tetris
//
//  Created by Phil Stern on 5/23/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//
//  CountdownLabelNode is a subclass of SKLabelNode.  Initially, it has no text, so nothing is
//  displayed, until member function showCountdown is called.  Setting isHidden may not be
//  necessary.
//

import Foundation
import SpriteKit

class CountdownLabelNode: SKLabelNode {

    var isCountingDown = false
    
    func showCountdown(from count: Int, completionHandler: @escaping () -> Void) {
        let duration = 0.5
        let grow = SKAction.scale(to: 1.0, duration: duration)
        let shrink = SKAction.scale(to: 0.0, duration: duration)

        if count == 0 {
            text = "Go!"
        } else {
            text = String(count)
        }
        
        if !isCountingDown {
            isCountingDown = true
            setScale(0.0)
            isHidden = false
        }
        run(
            SKAction.sequence([grow, shrink]),
            completion: {
                if count == 0 {
                    self.isCountingDown = false
                    self.isHidden = true
                    completionHandler()
                } else {
                    self.showCountdown(from: count - 1, completionHandler: completionHandler)  // call recursively with one less count, until 0
                }
        }
        )
    }
}
