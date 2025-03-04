//
//  ReportUserViewController.swift
//  UniConnect
//
//  Created by Yash Thakkar on 12/11/23.
//

import UIKit
import FirebaseFirestore

class ReportUserViewController: UIViewController {
    
    var reportedUserID: String?
    
    var onReportSubmission: (() -> Void)?
    
    let submitButton = UIButton(type: .system)
    
    let questionLabel = UILabel()
    
    let options = ["Spam", "Vulgar Media", "Privacy Violation", "Child Safety", "Harassment/Bullying", "Violent Acts", "Other"]
    var selectedOption: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        print("Reported User ID: \(reportedUserID ?? "No ID received")")
        
        // Setup Cancel Button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        // Title Label
        let titleLabel = UILabel()
        titleLabel.text = "Report User"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Question Label
        questionLabel.text = "Why are you reporting this user?"
        questionLabel.textColor = .white
        questionLabel.textAlignment = .center
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(questionLabel)

        // Constraints for Cancel Button, Title Label, and Question Label
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: cancelButton.bottomAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            questionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            questionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        setupOptionButtons()

            submitButton.setTitle("Submit", for: .normal)
            submitButton.backgroundColor = UIColor.systemBlue
            submitButton.setTitleColor(.white, for: .normal)
            submitButton.layer.cornerRadius = 10
            submitButton.addTarget(self, action: #selector(submitReport), for: .touchUpInside)
            submitButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(submitButton)

        // Constraints for Submit Button
        NSLayoutConstraint.activate([
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            submitButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            submitButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            submitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            submitButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupOptionButtons() {
        var lastButton: UIButton?
        for option in options {
            let button = UIButton()
            button.setTitle(option, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 15
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.cgColor
            button.addTarget(self, action: #selector(optionSelected(_:)), for: .touchUpInside)
            button.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(button)

            // Constraints
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: lastButton?.bottomAnchor ?? questionLabel.bottomAnchor, constant: 20),
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
            lastButton = button
        }
    }

    @objc func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func optionSelected(_ sender: UIButton) {
        selectedOption = sender.title(for: .normal)
        print("Option selected: \(selectedOption ?? "none")")
        for subview in view.subviews {
            if let button = subview as? UIButton, options.contains(button.title(for: .normal) ?? "") {
                button.backgroundColor = button == sender ? .gray : .clear
                button.setTitleColor(button == sender ? .black : .white, for: .normal)
            }
        }
    }
    

    
    @objc func submitReport() {
        print("Submit button tapped.")
        guard let uid = reportedUserID, let reason = selectedOption else {
            print("Missing user ID or reason for report.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").whereField("uid", isEqualTo: uid).getDocuments { [weak self] (querySnapshot, error) in
            if let error = error {
                print("Error retrieving user document: \(error.localizedDescription)")
                return
            }

            guard let self = self, let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("No documents found for UID: \(uid)")
                return
            }

            let userData = documents.first!.data()
            let firstname = userData["firstname"] as? String ?? "Unknown"
            let lastname = userData["lastname"] as? String ?? "Unknown"
            let reportedEmail = userData["email"] as? String ?? "Unknown"

            let reportData: [String: Any] = [
                "firstname": firstname,
                "lastname": lastname,
                "reason": reason,
                "uid": uid,
                "reportedEmail": reportedEmail,
                "reportTime": Timestamp(date: Date())
            ]

            db.collection("reports").addDocument(data: reportData) { error in
                if let error = error {
                    print("Error reporting user: \(error.localizedDescription)")
                } else {
                    print("User reported successfully.")
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }





}

