//
//  HomeViewController.swift
//  BearPong
//
//  Created by Walt Leung on 7/29/17.
//  Copyright © 2017 Walt Leung. All rights reserved.
//

import UIKit
// import SwiftSocket

class HomeViewController: UIViewController {
    
    @IBOutlet weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        button.setTitle("Tap to Play", for: .normal)
        button.tintColor = UIColor.black
        button.titleLabel?.font = UIFont(name: "Avenir", size: 14)
        button.layer.cornerRadius = 5
        button.clipsToBounds = true
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.black.cgColor
        // Do any additional setup after loading the view.
    }
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        
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
