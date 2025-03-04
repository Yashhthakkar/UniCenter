// Akshar - Purushottam Maharaj ni Jai
//  LoginViewController.swift
//  UniCenter
//
//  Created by Yash Thakkar on 5/5/23.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var collegeEmail: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        setUpElements()
        
        if Auth.auth().currentUser != nil {
            // User is signed in. Go to home screen
            transitionToHome()
        }
        
    }
    
    func setUpElements() {
        
        //Hide Error Label
        errorLabel.alpha = 0
        
        //Style Elements
        Utilities.styleTextField(collegeEmail)
        Utilities.styleTextField(passwordTextField)
        styleTextFieldWithPlaceholder(collegeEmail, placeholderColor: UIColor.white, textColor: UIColor.black)
        styleTextFieldWithPlaceholder(passwordTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        Utilities.styleFilledButton(loginButton)
    }
    
    func styleTextFieldWithPlaceholder(_ textField: UITextField, placeholderColor: UIColor, textColor: UIColor) {
        Utilities.styleTextField(textField)
        textField.textColor = textColor
        if let placeholderText = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        }
    }
    
    
    @IBAction func loginTapped(_ sender: Any) {
        
        // TODO: Validate Fields
        
        // Create cleaned versions of the text field
        let email = collegeEmail.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Sign in the user
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if error != nil {
                // Couldn't sign in
                self.errorLabel.text = error!.localizedDescription
                self.errorLabel.alpha = 1
            } else {
                if let centralVC = self.storyboard?.instantiateViewController(withIdentifier: "CentralVC") as? UITabBarController {
                    self.view.window?.rootViewController = centralVC
                    self.view.window?.makeKeyAndVisible()
                }
            }
            
        }
    }
    
    
    
    @IBAction func forgotPassButton_Tapped(_ sender: Any) {
        self.performSegue(withIdentifier: "forgotPassSegue", sender: nil)
    }
    
    
    func transitionToHome() {
        if let centralVC = storyboard?.instantiateViewController(withIdentifier: "CentralVC") as? UITabBarController {
            view.window?.rootViewController = centralVC
            view.window?.makeKeyAndVisible()
        }
    }
    
    
    
}
