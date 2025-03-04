// Akshar - Purushottam Maharaj ni Jai
//  WelcomeViewController.swift
//  UniCenter
//
//  Created by Yash Thakkar on 5/5/23.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var loginButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        setUpElements()
    }
    
    func setUpElements(){
        Utilities.styleFilledButton(signUpButton)
        Utilities.styleFilledButton(loginButton)
    }
    

}
