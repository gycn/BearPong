//
//  ARObject.swift
//  BearPong
//
//  Created by Walt Leung on 7/29/17.
//  Copyright © 2017 Walt Leung. All rights reserved.
//

import UIKit
import SceneKit

class ARObject: SCNNode {
    override init () {
        super.init()
    }
    
    func getPos() -> SCNVector3 {
        return self.position
    }
    
    func getRotation() -> SCNVector4 {
        return self.rotation
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
