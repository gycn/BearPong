//
//  ViewController.swift
//  BearPong
//
//  Created by Walt Leung on 7/29/17.
//  Copyright © 2017 Walt Leung. All rights reserved.
//

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
    var receivedData = ""
    var doesBallExist = false
    
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
            Timer.scheduledTimer(timeInterval: 3, target: self, selector: Selector(("sendData")), userInfo: nil, repeats: true)
            Timer.scheduledTimer(timeInterval: 3, target: self, selector: Selector(("receiveData")), userInfo: nil, repeats: true)
        case .failure(let error):
            print("error2")
            print(error)
        }
    }
    
    func sendData() {
        switch client.send(string: "fuck you") {
        case .success:
            print("success2")
        case .failure(let error):
            print("error1")
            print(error)
        }
    }

    func receiveData() {
        guard let data = client.read(1024*10) else { return }
        if let response = String(bytes: data, encoding: .utf8) {
            textLabel.text = response
            self.receivedData = response
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
