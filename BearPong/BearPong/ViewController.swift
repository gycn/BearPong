//
//  ViewController.swift
//  BearPong
//
//  Created by Walt Leung on 7/29/17.
//  Copyright © 2017 Walt Leung. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit
import SwiftSocket

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var textLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var addr = "192.168.0.103"
    var prt = 8007
    var client:TCPClient = TCPClient(address: "192.168.0.103", port: Int32(8007))
    var doesBallExist = false
    
    // Opcodes
    let UPDATE_USER_SPATIAL_INFORMATION_OPCODE = 0x00
    let SELECT_OBJECT_OPCODE = 0x01
    let UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE = 0x10
    let SEND_USER_ID_OPCODE = 0x11
    let SELECT_OBJECT_RESPONSE_OPCODE = 0x12
    
    // Opcodes
    var receivedOpcode: Int = 0
    var sentInstruction: [UInt8] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true
        
        socketSetup()
        
        // Setup timers
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func socketSetup() {
        switch client.connect(timeout: 3) {
        case .success:
            print("success!")
            sendData()
            Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.sendData), userInfo: nil, repeats: true)
            Timer.scheduledTimer(timeInterval: 0.10, target: self, selector: #selector(ViewController.receiveData), userInfo: nil, repeats: true)
        case .failure(let error):
            print("error2")
            print(error)
        }
    }
    
    @objc func sendData() {
        switch client.send(string: "fuck you") {
        case .success:
            print("success2")
        case .failure(let error):
            print("error1")
            print(error)
        }
    }

    @objc func receiveData() {
        guard let data = client.read(1024*10) else { return }
        if let response = String(bytes: data, encoding: .utf8) {
            textLabel.text = response
        }
        userUpdate(instruction: data)
    }
    
    func userUpdate(instruction: [UInt8]) {
        let array = instruction[0...1]
        let data = Data(bytes: array)
        let receivedOpcode = Int(UInt32(bigEndian: data.withUnsafeBytes { $0.pointee }))
        switch receivedOpcode {
        case UPDATE_USER_SPATIAL_INFORMATION_OPCODE:
            return
        case SELECT_OBJECT_OPCODE:
            return
        case UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE:
            let objectID = instruction[2...9]
            let new_object_matrix = instruction[10...127]

        case SEND_USER_ID_OPCODE:
            let userID = instruction[2...9]

        case SELECT_OBJECT_RESPONSE_OPCODE:
            let response = [2...3]
        default:
            print("hi")

    
        }
//        if receivedOpcode == UPDATE_USER_SPATIAL_INFORMATION_OPCODE {
//
//        } else if receivedOpcode == SELECT_OBJECT_OPCODE {
//
//        } else if receivedOpcode == UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE {
//
//        } else if receivedOpcode == SEND_USER_ID_OPCODE {
//
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSession()
    }
    
    func configureSession() {
        if ARWorldTrackingSessionConfiguration.isSupported {
            let configuration = ARWorldTrackingSessionConfiguration()
            configuration.planeDetection = ARWorldTrackingSessionConfiguration.PlaneDetection.horizontal
            sceneView.session.run(configuration)
        } else {
            let configuration = ARSessionConfiguration()
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view’s session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if doesBallExist == true {
            return
        }
        let ballNode = Ball()
        let (direction, position) = self.getUserVector()
        ballNode.position = position
        
        let ballDir = direction
        ballNode.physicsBody?.applyForce(ballDir, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ballNode)
        doesBallExist = true
    }
    
    struct CollisionCategory: OptionSet {
        let rawValue: Int
        static let ball  = CollisionCategory(rawValue: 1 << 0) // 00...01
        static let user = CollisionCategory(rawValue: 1 << 1) // 00..10
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) {
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            
            return (dir, pos)
        }
        return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
    }
}
