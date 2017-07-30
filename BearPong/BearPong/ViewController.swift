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
    
    // New Ball Object
    var ballNode = Ball()
    
    // UserID
    var userID: Int = 0
    
    // Frames per second or refresh rate
    var FPS: Int = 15
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide yo balls
        ballNode.isHidden = true

        
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
            // Start sending and receiving data at FPS intervals
            Timer.scheduledTimer(timeInterval: 1/FPS, target: self, selector: #selector(ViewController.sendData), userInfo: nil, repeats: true)
            Timer.scheduledTimer(timeInterval: 1/FPS, target: self, selector: #selector(ViewController.receiveData), userInfo: nil, repeats: true)
        case .failure(let error):
            print(error)
        }
    }
    
    @objc func sendData() {
        switch client.send(data: sentInstruction) {
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
    
    // Get Instruction
    func userUpdate(instruction: [UInt8]) {
        let array = instruction[0...1]
        let receivedOpcode = byteArrayToInt(byteArray: Array(array))
        switch receivedOpcode {
        case UPDATE_USER_SPATIAL_INFORMATION_OPCODE:
            return
        case SELECT_OBJECT_OPCODE:
            return
        case UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE:
            let objectID = byteArrayToInt(byteArray: Array(instruction[2...9]))
            
            let positionX = byteArrayToFloat(byteArray: Array(instruction[10...17]))
            let positionY = byteArrayToFloat(byteArray: Array(instruction[18...25]))
            let positionZ = byteArrayToFloat(byteArray: Array(instruction[26...33]))
            let position = SCNVector3(positionX, positionY, positionZ)
            
            let orientationX = byteArrayToFloat(byteArray: Array(instruction[34...41]))
            let orientationY = byteArrayToFloat(byteArray: Array(instruction[42...49]))
            let orientationZ = byteArrayToFloat(byteArray: Array(instruction[50...57]))
            let orientation = SCNVector3(orientationX, orientationY, orientationZ)
            
            let velocityX = byteArrayToFloat(byteArray: Array(instruction[58...65]))
            let velocityY = byteArrayToFloat(byteArray: Array(instruction[66...73]))
            let velocityZ = byteArrayToFloat(byteArray: Array(instruction[74...81]))
            let velocity = SCNVector3(velocityX, velocityY, velocityZ)
            
            ballNode.position = position
//            ballNode.orientation = orientation
            ballNode.velocity = velocity
            return
            
        case SEND_USER_ID_OPCODE:
            let userID = byteArrayToInt(byteArray: Array(instruction[2...9]))
            self.userID = userID

        case SELECT_OBJECT_RESPONSE_OPCODE:
            let response = byteArrayToInt(byteArray: Array(instruction[2...3]))
            
        default:
            print("hi")
        }
    }
    
    func vectorToByteArray(vector: SCNVector3) -> [UInt8] {
        let X = floatToByteArray(value: vector.x)
        let Y = floatToByteArray(value: vector.y)
        let Z = floatToByteArray(value: vector.z)
        return X + Y + Z
    }

    // Update User Spatial Information
    func updateUserSpatialInformation(position: Float, orientation: Float) {
        let opcodeArray = intToByteArray(value: 00)
        let positionArray = floatToByteArray(value: position)
        
        // orientation needs to be 4D
        let orientationArray = floatToByteArray(value: orientation)
        let instruction = opcodeArray + positionArray + orientationArray
        sentInstruction = instruction
    }
    
    // Select Object
    func selectObject(objectID: Int) {
        let opcodeArray = intToByteArray(value: 00)
        let objectIDArray = intToByteArray(value: objectID)
        let instruction = opcodeArray + objectIDArray
        sentInstruction = instruction
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
        ballNode.isHidden = false
        let (direction, position) = self.getUserVector()
        ballNode.position = position
        
        let ballDir = direction
        
        var gameExisting = true
        var playerWins = false
        
        let velocity = Float(0.5) //meters/second
        let timeStep = Float(0.0083333333333333) //seconds
        
        while (gameExisting) {
            ballNode.position = SCNVector3(
                ballNode.position.x + velocity * timeStep,
                ballNode.position.y + velocity * timeStep,
                ballNode.position.z + velocity * timeStep)
            sceneView.scene.rootNode.addChildNode(ballNode)
            doesBallExist = true
            
            //TODO - Conditions to change  playerWins
            
            if (playerWins) {
                gameExisting = false
            }
        }
//        ballNode.physicsBody?.applyForce(ballDir, asImpulse: true)
//        sceneView.scene.rootNode.addChildNode(ballNode)
//        doesBallExist = true
    }
    
    struct CollisionCategory: OptionSet {
        let rawValue: Int
        static let ball  = CollisionCategory(rawValue: 1 << 0) // 00...01
        static let user = CollisionCategory(rawValue: 1 << 1) // 00..10
    }
    
    func getUserVector() -> (SCNVector3, SCNVector3) {
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let ori = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            updateUserSpatialInformation(position: vectorToByteArray(vector: pos), orientation: vectorToByteArray(vector: ori))
            return (pos, ori)
        }
        return (SCNVector3(0, 0, -0.2), SCNVector3(0, 0, -1))
    }
    
    func byteArrayToFloat(byteArray: [UInt8]) -> Float {
        let data = Data(bytes: byteArray)
        return Float(UInt32(bigEndian: data.withUnsafeBytes { $0.pointee }))
    }
    
    func byteArrayToInt(byteArray: [UInt8]) -> Int {
        let data = Data(bytes: byteArray)
        return Int(UInt32(bigEndian: data.withUnsafeBytes { $0.pointee }))
    }
    
    func intToByteArray(value: Int) -> [UInt8] {
        var value = value
        return withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Int>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Int>.size))
            }
        }
    }
    
    func floatToByteArray(value: Float) -> [UInt8] {
        var value = value
        return withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Float>.size) {
                Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Float>.size))
            }
        }
    }
}
