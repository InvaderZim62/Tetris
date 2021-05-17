//
//  Button.swift
//  Othello
//
//  Created by Phil Stern on 4/23/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import Foundation
import SpriteKit

protocol ButtonDelegate: AnyObject {
    func buttonClicked(sender: Button)
}

class Button: SKSpriteNode {
    
    weak var delegate: ButtonDelegate!
    
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        isUserInteractionEnabled = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate.buttonClicked(sender: self)
    }
}
