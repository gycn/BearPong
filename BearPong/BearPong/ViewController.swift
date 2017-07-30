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
//import SwiftSocket
import Socket


class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var textLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet var sendLabel: UILabel!
    
    // var client:TCPClient = TCPClient(address: "192.168.0.101", port: Int32(8007))
    var mySocket = try! Socket.create()
    
    
    var doesBallExist = false
    
    // Opcodes
    let UPDATE_USER_SPATIAL_INFORMATION_OPCODE = UInt8(0x00)
    let SELECT_OBJECT_OPCODE = UInt8(0x01)
    let UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE = UInt8(0x10)
    let SEND_USER_ID_OPCODE = UInt8(0x11)
    let SELECT_OBJECT_RESPONSE_OPCODE = UInt8(0x12)
    let ALLOWED_TO_START_GAME = UInt8(0xff)
    
    // Dictionary
    let COMMAND_LENGTHS: [Int: Int] = [0:0]
    // Opcodes
    var receivedOpcode: Int = 0
    var sentInstruction: [UInt8] = []
    
    // New Ball Object
    var ballNode = Ball()
    
    // UserID
    var userID:UInt32 = 0
    
    // Frames per second or refresh rate
    var FPS: Int = 15
    
    // ObjectID
    var objectID: Int = 0
    
    var receivedUserID = false
    
    var anchor = Ball()
    
    var anchorInitialized = false
    
    var gameAllowedToStart = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Hide yo balls
        ballNode.isHidden = true
        anchor.isHidden = true

        
        // Setup gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        view.addGestureRecognizer(tap)
        view.isUserInteractionEnabled = true

        // Setup command length dictionary
        var COMMAND_LENGTHS = [UPDATE_USER_SPATIAL_INFORMATION_OPCODE: 24, SELECT_OBJECT_OPCODE: 4, UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE: 68, SEND_USER_ID_OPCODE: 4, SELECT_OBJECT_RESPONSE_OPCODE: 1, ALLOWED_TO_START_GAME: 2]
        
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        sceneView.scene.physicsWorld.contactDelegate = self
        
        //Asynchronous
        
    }
    
    
    
    func socketSetup() {
        mySocket.readBufferSize = 32768
        do {
            try mySocket.connect(to: "192.168.0.101", port: 8007)
            try mySocket.setBlocking(mode: false)
        } catch {
            print("error")
        }
//        switch client.connect(timeout: 3) {
//        case .success:
//            print("hi")
//            // Start sending and receiving data at FPS intervals
//            // Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ViewController.sendData), userInfo: nil, repeats: true)
        
        _ = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.receiveData), userInfo: nil, repeats: true)
       Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(ViewController.getUserVector), userInfo: nil, repeats: true)
//        case .failure(let error):
//            print(error)
//        }
    }
    
    
    
    @objc func sendData() {
        do {
            try mySocket.write(from: Data(sentInstruction))
        } catch {
            return
        }
    }
    

    @objc func receiveData() {
        var readData = Data(capacity: 256)
        do {
            var num_bytes = try mySocket.read(into: &readData)
            if num_bytes > 0 {
                userUpdate(instruction: Array(readData))
            }
        } catch {
            return
        }
    }
    
    func convert_bytes_to_UInt32(arr : [UInt8], offset: Int) -> UInt32 {
        let data = Data(bytes: arr[offset...offset + 3])
        return UInt32(bigEndian: data.withUnsafeBytes { $0.pointee })
    }
    
    func convert_bytes_to_float(arr : [UInt8], offset: Int) -> Float {
        let data = Data(bytes: arr[offset...offset + 3])
        return Float(bitPattern: UInt32(bigEndian: data.withUnsafeBytes { $0.pointee } ))
    }
    
    func update_object_spatial_information(instruction: [UInt8]) {
        var objectID = convert_bytes_to_UInt32(arr : instruction, offset : 1)
        ballNode.position.x = convert_bytes_to_float(arr : instruction, offset : 5) + anchor.position.x
        ballNode.position.y = convert_bytes_to_float(arr : instruction, offset : 9) + anchor.position.y
        ballNode.position.z = convert_bytes_to_float(arr : instruction, offset : 13) + anchor.position.z
        
        ballNode.velocity.x = convert_bytes_to_float(arr : instruction, offset : 29)
        ballNode.velocity.y = convert_bytes_to_float(arr : instruction, offset : 33)
        ballNode.velocity.z = convert_bytes_to_float(arr : instruction, offset : 37)
    }
    
    // Get Instruction
    func userUpdate(instruction: [UInt8]) {
        while instruction.count > 0 {
        let opcode = instruction[0]
            switch opcode {
            case UPDATE_OBJECT_SPATIAL_INFORMATION_OPCODE:
                update_object_spatial_information(instruction : instruction)
                return
                
            case SEND_USER_ID_OPCODE:
                var uID = convert_bytes_to_UInt32(arr : instruction, offset : 1)
                self.userID = uID
                receivedUserID = true
                return
            case ALLOWED_TO_START_GAME:
                gameAllowedToStart = true
                textLabel.text = String(describing: gameAllowedToStart)
                ballNode.isHidden = false
                return
            case SELECT_OBJECT_RESPONSE_OPCODE:
                return
            
            default:
                return
            }
        }
    }
    
    func vectorToByteArray(vector: inout SCNVector3) -> [UInt8] {
        var arr = Data(buffer: UnsafeBufferPointer(start: &vector.x, count: 1))
        arr.append( Data(buffer: UnsafeBufferPointer(start: &vector.y, count: 1)))
        arr.append( Data(buffer: UnsafeBufferPointer(start: &vector.z, count: 1)))
        return Array(arr)
    }
    
    // Send Start/Enter Game Signal
    func enterGame() {
        let instruction = [UInt8(255), UInt8(1), UInt8(17)]
        do {
            try mySocket.write(from: Data(instruction))
        } catch {
            return
        }
    }
    
    // Update User Spatial Information If Byte Array
    func updateUserSpatialInformationByteArray(position: [UInt8], orientation: [UInt8]) {
        let opcodeArray = UInt8(00)
        let instruction = [opcodeArray] + position + orientation
        do {
            try mySocket.write(from: Data(instruction))
        } catch {
            return
        }
    }

    
    // Select Object
    func selectObject(objectID: inout Int) {
        let opcode = UInt8(00)
        let count = MemoryLayout<UInt32>.size
        let bytePtr = withUnsafePointer(to: &objectID) {
            $0.withMemoryRebound(to: UInt8.self, capacity: count) {
                UnsafeBufferPointer(start: $0, count: count)
            }
        }
        let byteArray = Array(bytePtr)
        let instruction = [opcode] + byteArray
        do {
            try mySocket.write(from: Data(instruction))
        } catch {
            return
        }
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
        if self.anchorInitialized == false {
            let (_, position) = self.initializeAnchorVector()
            self.anchor.position = position
            self.anchorInitialized = true
            socketSetup()
        } else {
            if (!gameAllowedToStart) {
                self.enterGame()
                gameAllowedToStart = true
            }

            let (direction, position) = self.initializeUserVector()

//            ballNode.position = position
//
//            let ballDir = direction
//
//            var gameExisting = true
//            var playerWins = false
//
//            let velocity = Float(0.5) //meters/second
//            let timeStep = Float(0.0083333333333333) //seconds
//            sceneView.scene.rootNode.addChildNode(ballNode)
        }
    }
    
    struct CollisionCategory: OptionSet {
        let rawValue: Int
        static let ball  = CollisionCategory(rawValue: 1 << 0) // 00...01
        static let user = CollisionCategory(rawValue: 1 << 1) // 00..10
    }
    
    func initializeAnchorVector() -> (SCNVector3, SCNVector3) {
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let ori = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            return (pos, ori)
        }
        return (SCNVector3(0, 0, -0.2), SCNVector3(0, 0, -1))
    }
    
    func initializeUserVector() -> (SCNVector3, SCNVector3) {
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let ori = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            let newPos = SCNVector3(pos.x - anchor.position.x, pos.y - anchor.position.y, pos.z - anchor.position.z)
            return (newPos, ori)
        }
        return (SCNVector3(0, 0, -0.2), SCNVector3(0, 0, -1))
    }
    
    @objc func getUserVector() {
        if self.anchorInitialized == false {
            return
        }
        if let frame = self.sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            var ori = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            var newPos = SCNVector3(pos.x - anchor.position.x, pos.y - anchor.position.y, pos.z - anchor.position.z)
            sendLabel.text = String(describing: newPos)
            updateUserSpatialInformationByteArray(position: vectorToByteArray(vector: &newPos), orientation: vectorToByteArray(vector: &ori))
        }
    }
}

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
