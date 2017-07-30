//
//  HomeViewController.swift
//  BearPong
//
//  Created by Walt Leung on 7/29/17.
//  Copyright © 2017 Walt Leung. All rights reserved.
//

import UIKit
import SwiftSocket

class HomeViewController: UIViewController {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var passwordField: UITextField!
    var password = ""
    var passwordArray = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordField.delegate = self as? UITextFieldDelegate
        passwordField.text = "Room Name"
        button.setTitle("Join Room", for: .normal)
        // Do any additional setup after loading the view.
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        self.password = passwordField.text!
        passwordArray.append(passwordField.text!)
        self.performSegue(withIdentifier: "ARViewSegue", sender: sender)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
