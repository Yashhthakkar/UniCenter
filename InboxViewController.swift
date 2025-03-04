//  Akshar - Purushottam Maharaj ni Jai
// InboxViewController.swift
// UniCenter
// Created by Yash Thakkar on 5/3/23.

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Contacts

class InboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    struct Contact {
        var phoneNumber: String
    }
    
    struct Notification {
        var message: String
        var timestamp: Date
        var identifier: String
        var contactName: String?
        var profilePictureURL: String?
        var phoneNumber: String?
    }

    var tableView: UITableView!
    var notifications = [Notification]()
    var cachedMatches = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadWelcomeNotification()
        fetchAndProcessContacts()
        listenForNewMatches()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestContactAccess()
    }
    
    private func requestContactAccess() {
        let store = CNContactStore()
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            self.fetchAndProcessContacts()
        case .notDetermined:
            store.requestAccess(for: .contacts) { [weak self] granted, error in
                DispatchQueue.main.async {
                    if granted {
                        self?.fetchAndProcessContacts()
                    } else {
                        self?.showContactPermissionDeniedAlert()
                    }
                }
            }
        case .restricted, .denied:
            showContactPermissionDeniedAlert()
        default:
            break
        }
    }

    private func showContactPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Permission Denied", message: "Access to contacts was denied. Please enable access in Settings to use this feature.", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

    private func setupTableView() {
        print("Setting up table view")
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "notificationCell")
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        view.addSubview(tableView)
    }

    private func loadWelcomeNotification() {
        print("Loading welcome notification")
        let welcomeNotification = Notification(message: "Welcome to UniCenter! Explore around to connect withe others.", timestamp: Date(), identifier: "welcomeNotification")
        self.notifications.append(welcomeNotification)
        self.tableView.reloadData()
    }

   // MARK: - Contact Processing
    private func fetchAndProcessContacts() {
        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask(withName: "FetchContactsTask") {

            if taskID != .invalid {
                UIApplication.shared.endBackgroundTask(taskID)
                taskID = .invalid
            }
        }

        DispatchQueue.global(qos: .background).async {
            let contacts = self.fetchContacts()
            let phoneNumbers = contacts.map { self.formatPhoneNumber($0.phoneNumber) }

            self.checkContactsAgainstFirestore(phoneNumbers: phoneNumbers) { matches in
                DispatchQueue.main.async {
                    for match in matches {
                        let notification = Notification(message: "Connect with \(match)", timestamp: Date(), identifier: "userSuggestion", contactName: match)
                        self.notifications.append(notification)
                    }
                    self.tableView.reloadData()

                    if taskID != .invalid {
                        UIApplication.shared.endBackgroundTask(taskID)
                        taskID = .invalid
                    }
                }
            }
        }
    }

    private func formatPhoneNumber(_ number: String) -> String {
        return number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }

    private func fetchContacts() -> [Contact] {
        var contacts = [Contact]()

        return contacts
    }

    private func checkContactsAgainstFirestore(phoneNumbers: [String], completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        var matches = [String]()

        let group = DispatchGroup()
        for number in phoneNumbers {
            group.enter()
            db.collection("users").whereField("phoneNumber", isEqualTo: number).getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else if let documents = querySnapshot?.documents, !documents.isEmpty {
                    let data = documents.first!.data()
                    if let firstName = data["firstname"] as? String, let lastName = data["lastname"] as? String {
                        matches.append("\(firstName) \(lastName)")
                    }
                } else {
                    print("No document found for number: \(number)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(matches)
        }
    }

    // MARK: - TableView DataSource and Delegate methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }

    // MARK: - TableView DataSource and Delegate methods
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "notificationCell", for: indexPath)
        let notification = notifications[indexPath.row]

        cell.textLabel?.text = notification.message
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping

        if notification.identifier == "welcomeNotification" {
            // Bell icon for welcome notification
            cell.imageView?.image = UIImage(systemName: "bell.fill")
            cell.imageView?.layer.add(shakeAnimation(), forKey: "shakeAnimation")
            cell.imageView?.tintColor = .systemYellow
        } else {
            // Placeholder
            cell.imageView?.image = UIImage(systemName: "person.fill")
            cell.imageView?.layer.cornerRadius = cell.imageView!.frame.size.width / 2
            cell.imageView?.clipsToBounds = true

            if let urlString = notification.profilePictureURL, let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.imageView?.image = image
                            cell.imageView?.layer.cornerRadius = cell.imageView!.frame.size.width / 2
                            cell.imageView?.clipsToBounds = true
                            cell.setNeedsLayout()  // This is important to update the cell layout
                        }
                    }
                }.resume()
            }
        }

        return cell
    }






    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let notification = notifications[indexPath.row]

        // Redirect only for match notifications
        if notification.identifier != "welcomeNotification",
           let phoneNumber = notification.phoneNumber {
            fetchCurrentUserName { userName in
                let defaultText = "Hi! We connected on UniCenter. My name is \(userName)."
                if let encodedText = defaultText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                   let url = URL(string: "sms:\(phoneNumber)?&body=\(encodedText)") {
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    

    func fetchCurrentUserName(completion: @escaping (String) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            completion("Unknown")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                completion("Unknown")
                return
            }

            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("No documents found")
                completion("Unknown")
                return
            }

            let data = documents.first!.data()
            if let firstName = data["firstname"] as? String {
                completion(firstName)
            } else {
                print("Firstname field not found")
                completion("Unknown")
            }
        }
    }







    func shakeAnimation() -> CAAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation")
        let angle = CGFloat.pi / 12
        animation.values = [angle, -angle, angle]
        animation.duration = 0.2
        animation.repeatCount = 3
        animation.isAdditive = true
        return animation
    }
    
    
    
    
    func listenForNewMatches() {
        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Current user ID not found")
            return
        }

        print("Listening for new matches for user ID: \(currentUserID)")

        let userRef = Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID)
        userRef.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self, let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            print("Fetched user document successfully")

            if let data = documents.first?.data() {
                print("User data: \(data)")

                if let matchedWith = data["matchedWith"] as? [String] {
                    print("Matched with these UIDs: \(matchedWith)")

                    let newMatches = matchedWith.filter { !self.cachedMatches.contains($0) }
                    print("New matches found: \(newMatches)")

                    for uid in newMatches {
                        self.fetchMatchDetails(matchUID: uid)
                        self.cachedMatches.append(uid)
                    }
                } else {
                    print("No 'matchedWith' field found or it's empty")
                }
            }
        }
    }

    func fetchMatchDetails(matchUID: String) {
        print("Fetching match details for UID: \(matchUID)")

        Firestore.firestore().collection("users").whereField("uid", isEqualTo: matchUID).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self, let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("Error fetching matched user details: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            print("Match details fetched successfully for UID: \(matchUID)")

            if let data = documents.first?.data() {
                print("Match data: \(data)")

                if let firstname = data["firstname"] as? String,
                    let phoneNumber = data["phoneNumber"] as? String,
                    let profilePicURL = data["profilePictureURL"] as? String {
                    
                    let notification = Notification(
                        message: "\(firstname)likes you back! Click here to get in touch.",
                        timestamp: Date(),
                        identifier: matchUID,
                        contactName: firstname,
                        profilePictureURL: profilePicURL,
                        phoneNumber: phoneNumber
                    )
                    DispatchQueue.main.async {
                        print("Appending new match notification")
                        self.notifications.append(notification)
                        self.tableView.reloadData()
                    }
                } else {
                    print("Firstname or phoneNumber not found in match data")
                }
            } else {
                print("No data found for matched user")
            }
        }
    }





}


