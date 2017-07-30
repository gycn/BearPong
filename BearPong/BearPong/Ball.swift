//
//  Ball.swift
//  BearPong
//
//  Created by Walt Leung on 7/29/17.
//  Copyright © 2017 Walt Leung. All rights reserved.
//

import UIKit
import SceneKit

class Ball: ARObject {
    override init () {
        super.init()
        let sphere = SCNSphere(radius: 0.05)
        self.geometry = sphere
        let shape = SCNPhysicsShape(geometry: sphere, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        
        self.physicsBody?.categoryBitMask = ViewController.CollisionCategory.ball.rawValue
        self.physicsBody?.contactTestBitMask = ViewController.CollisionCategory.user.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
