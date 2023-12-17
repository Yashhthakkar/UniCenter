// Akshar - Purushottam Maharaj ni Jai
//  ForgotPassViewController.swift
//  UniCenter
//
//  Created by Yash Thakkar on 5/18/23.
//

import UIKit
import Firebase

class ForgotPassViewController: UIViewController {

    @IBOutlet weak var collegeEmail: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func forgotPassButton_Tapped(_ sender: Any) {
        guard let email = collegeEmail.text, !email.isEmpty else {
            let alert = Service.createAlertController(title: "Input Error", message: "Please enter your college email address.")
            self.present(alert, animated: true, completion: nil)
            return
        }

        let auth = Auth.auth()

        auth.sendPasswordReset(withEmail: email) { error in
            if let error = error {
                let alert = Service.createAlertController(title: "Error", message: error.localizedDescription)
                self.present(alert, animated: true, completion: nil)
                return
            }

            let alert = Service.createAlertController(title: "Success!", message: "A password reset email has been sent! Check your junk folder if the email can't be found in your inbox.")
            self.present(alert, animated: true, completion: nil)
            
            //clear text field after email sent
            self.collegeEmail.text = ""
        }
    }


}
