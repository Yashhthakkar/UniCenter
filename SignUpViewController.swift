//  Akshar - Purushottam Maharaj ni Jai
//  SignUpViewController.swift
//  UniCenter
//
//  Created by Yash Thakkar on 5/5/23.
//

import UIKit
import FirebaseAuth
import Firebase

class SignUpViewController: UIViewController {

    @IBOutlet weak var firstNameTextField: UITextField!
    
    @IBOutlet weak var lastNameTextField: UITextField!
    
    @IBOutlet weak var collegeEmailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var termsLabel: UILabel!
    
    
    @IBOutlet weak var termsSwitch: UISwitch!
    
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBOutlet weak var errorLabel: UILabel!
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpElements()
        
        if Auth.auth().currentUser != nil {
                // Go to home screen after sign in
                transitionToHome()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(termsLabelTapped))
        termsLabel.isUserInteractionEnabled = true
        termsLabel.addGestureRecognizer(tapGesture)
        
        let attributedString = NSMutableAttributedString(string: "I have read & accepted the ")
        let termsText = NSAttributedString(string: "privacy policy",
                                           attributes: [.foregroundColor: UIColor.blue,
                                                        .underlineStyle: NSUnderlineStyle.single.rawValue])
        attributedString.append(termsText)
        termsLabel.attributedText = attributedString
    }
    
    @objc func termsLabelTapped() {
        if let url = URL(string: "https://sites.google.com/view/unicenterprivacypolicy/home") {
            UIApplication.shared.open(url)
        }
    }
    
    func setUpElements() {
        
        errorLabel.alpha = 0
        
        Utilities.styleTextField(firstNameTextField)
        Utilities.styleTextField(lastNameTextField)
        Utilities.styleTextField(collegeEmailTextField)
        Utilities.styleTextField(phoneNumberTextField)
        Utilities.styleTextField(passwordTextField)
        Utilities.styleTextField(confirmPasswordTextField)
        styleTextFieldWithPlaceholder(firstNameTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        styleTextFieldWithPlaceholder(lastNameTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        styleTextFieldWithPlaceholder(collegeEmailTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        styleTextFieldWithPlaceholder(phoneNumberTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        styleTextFieldWithPlaceholder(passwordTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        styleTextFieldWithPlaceholder(confirmPasswordTextField, placeholderColor: UIColor.white, textColor: UIColor.black)
        Utilities.styleFilledButton(signUpButton)
    }
    
    func styleTextFieldWithPlaceholder(_ textField: UITextField, placeholderColor: UIColor, textColor: UIColor) {
        Utilities.styleTextField(textField)
        textField.textColor = textColor
        if let placeholderText = textField.placeholder {
            textField.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor])
        }
    }

    
    func validateFields() -> String? {
        
        if firstNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || lastNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || phoneNumberTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || collegeEmailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {

            return "Please fill in all fields."
        }
        
        
        let email = collegeEmailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            if !email.hasSuffix("@gatech.edu") {
                return "UniCenter is currently operational on Georgia Tech's campus only."
        }
        
        let cleanedPassword = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let cleanedConfirmPassword = confirmPasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanedPassword != cleanedConfirmPassword {
                return "Error: Passwords do not match."
            }

        if Utilities.isPasswordValid(cleanedPassword) == false {
            return "Password needs to be atleast 8 characters, contains a special character and a number."
        }
        
        if !termsSwitch.isOn {
            return "Please accept the privacy policy to proceed."
        }
        
        return nil
    }
    
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        
    }
    
    
    
    
    @IBAction func signedUpTapped(_ sender: Any) {
        
        let error = validateFields()
        
        if error != nil {
            
            showError(error!)
        }
        else {
            
            // Create cleaned versions of the data
            let firstName = firstNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let lastName = lastNameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let email = collegeEmailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let phoneNumber = phoneNumberTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let confirmPassword = confirmPasswordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            // Create the user
            Auth.auth().createUser(withEmail: email, password: password) {
                (result, err) in
                
                if err != nil {
                    self.showError("Error creating user")
                }
                else {
                    
                    // User was created successfully, now store the first and last name
                    let db = Firestore.firestore()
                    
                    db.collection("users").addDocument(data: ["firstname": firstName, "lastname": lastName, "email": email, "phoneNumber": phoneNumber, "uid": result!.user.uid ]) { (error) in
                        
                        if error != nil {
                            self.showError("Error saving user data")
                        }
                    }
                    
                    self.transitionToHome()
                    
                }
            }
        }
        
    }
    
    func showError(_ message:String) {
        errorLabel.text = message
        errorLabel.alpha = 1
    }
    

    
    func transitionToHome() {
        if let centralVC = storyboard?.instantiateViewController(withIdentifier: "CentralVC") as? UITabBarController {
            view.window?.rootViewController = centralVC
            view.window?.makeKeyAndVisible()
        }
    }

}

