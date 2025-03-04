//  Akshar-Purshottam Maharaj ni Jai
//  AttractedToPage.swift
//  UniConnect
//  Created by Yash Thakkar on 12/6/23.
//  An Andromeda Production

import UIKit
import FirebaseFirestore
import FirebaseAuth

class AttractedToPage: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var attractedUserIDs: [String] = []
    var attractedUserInfo: [(firstname: String, lastname: String, profilePictureURL: String)] = []
    var tableView: UITableView!
    var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .gray
        
        setupTitleLabel()
        fetchCurrentUserAttractedTo()
        setupTableView()
    }
    
    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Attracted To:"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 35)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func fetchCurrentUserAttractedTo() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self,
                  let documents = querySnapshot?.documents,
                  !documents.isEmpty else {
                print("Error fetching user document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let data = documents.first?.data()
            if let attractedTo = data?["attractedTo"] as? [String], !attractedTo.isEmpty {
                self.attractedUserIDs = attractedTo
                self.fetchAttractedUserDetails()
            } else {
                print("No users in attractedTo array or array is empty")
            }
        }
    }

    private func fetchAttractedUserDetails() {
        let group = DispatchGroup()
        for uid in attractedUserIDs {
            group.enter()
            Firestore.firestore().collection("users").whereField("uid", isEqualTo: uid).getDocuments { [weak self] (querySnapshot, error) in
                defer { group.leave() }
                if let document = querySnapshot?.documents.first {
                    let data = document.data()
                    let firstname = data["firstname"] as? String ?? "Unknown"
                    let lastname = data["lastname"] as? String ?? "Unknown"
                    let profilePictureURL = data["profilePictureURL"] as? String ?? ""
                    self?.attractedUserInfo.append((firstname, lastname, profilePictureURL))
                } else {
                    print("Error fetching user details for uid: \(uid) - \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        group.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }

    private func setupTableView() {
        tableView = UITableView()
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: "UserCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attractedUserInfo.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UserCell", for: indexPath) as! UserTableViewCell
        let userInfo = attractedUserInfo[indexPath.row]
        cell.configure(with: userInfo)
        return cell
    }
}

class UserTableViewCell: UITableViewCell {
    let profileImageView = UIImageView()
    let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupProfileImageView()
        setupNameLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupProfileImageView() {
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)

        NSLayoutConstraint.activate([
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 40),
            profileImageView.heightAnchor.constraint(equalToConstant: 40)
        ])

        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
    }

    private func setupNameLabel() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10)
        ])

        nameLabel.font = UIFont.systemFont(ofSize: 16)
    }

    func configure(with userInfo: (firstname: String, lastname: String, profilePictureURL: String)) {
        nameLabel.text = "\(userInfo.firstname) \(userInfo.lastname)"
        loadProfileImage(from: userInfo.profilePictureURL)
    }

    private func loadProfileImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            profileImageView.image = UIImage(named: "defaultProfileImage")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.profileImageView.image = image
                }
            }
        }.resume()
    }
}


extension AttractedToPage {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteUserInfo(at: indexPath)
        }
    }

    private func deleteUserInfo(at indexPath: IndexPath) {
        let uidToRemove = attractedUserIDs[indexPath.row]

        attractedUserInfo.remove(at: indexPath.row)
        attractedUserIDs.remove(at: indexPath.row)

        tableView.deleteRows(at: [indexPath], with: .automatic)

        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        // Find the document with the matching UID
        Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error finding user document: \(error)")
                return
            }

            guard let document = querySnapshot?.documents.first else {
                print("User document not found")
                return
            }

            document.reference.updateData([
                "attractedTo": FieldValue.arrayRemove([uidToRemove])
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error)")
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }

    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}
