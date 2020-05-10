//
//  Utilities.swift
//  Cube
//
//  Created by Phil Stern on 2/22/20.
//  Copyright © 2020 Phil Stern. All rights reserved.
//

import Foundation
import SceneKit

func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
    return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
}

func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
    return abs(lhs.x - rhs.x) < 0.00001 && abs(lhs.y - rhs.y) < 0.00001 && abs(lhs.z - rhs.z) < 0.00001
}
