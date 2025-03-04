//
//  Service.swift
//  UniConnect
//
//  Created by Yash Thakkar on 5/18/23.
//

import UIKit
import Firebase

class Service {
    static func createAlertController(title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(okAction)
        
        return alert
    }
}
