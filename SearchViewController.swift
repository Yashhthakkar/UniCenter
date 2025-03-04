// SearchViewController.swift

import UIKit
import Firebase

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {

    // MARK: - Properties
    
    private var users = [User]()
    private var filteredUsers = [User]()
    private var searchBar = UISearchController(searchResultsController: nil)
    private var tableView: UITableView!
    
    
    private let reuseIdentifier = "UserCell"

    
    class UserCell: UITableViewCell {

        // MARK: - Properties

        let profileImageView: UIImageView = {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFill
            iv.clipsToBounds = true
            iv.layer.cornerRadius = 24
            iv.translatesAutoresizingMaskIntoConstraints = false
            return iv
        }()

        let nameLabel: UILabel = {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        var user: User? {
            didSet {
                guard let user = user else { return }
                print("Setting cell for user: \(user.firstName)")
                nameLabel.text = "\(user.firstName) \(user.lastName)"

                if let url = URL(string: user.profileImageUrl), user.profileImageUrl != "" {
                    URLSession.shared.dataTask(with: url) { (data, response, error) in
                        if let error = error {
                            print("Failed fetching image:", error)
                            return
                        }

                        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                            print("Failed fetching image: \(response)")
                            return
                        }

                        if let data = data {
                            DispatchQueue.main.async {
                                self.profileImageView.image = UIImage(data: data)
                            }
                        }
                    }.resume()
                } else {
                    self.profileImageView.image = nil
                }
            }
        }

        // MARK: - Lifecycle

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            setupSubviews()
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Helpers

        func setupSubviews() {
            contentView.addSubview(profileImageView)
            contentView.addSubview(nameLabel)

            NSLayoutConstraint.activate([
                profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
                profileImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                profileImageView.widthAnchor.constraint(equalToConstant: 48),
                profileImageView.heightAnchor.constraint(equalToConstant: 48),

                nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 12),
                nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
            ])
        }
    }

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[SearchViewController] viewDidLoad")
        
        configureSearchBar()
        configureTableView()
        fetchUsers()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            print("[SearchViewController] viewWillAppear")
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            print("[SearchViewController] viewDidAppear")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            print("[SearchViewController] viewWillDisappear")
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            print("[SearchViewController] viewDidDisappear")
        }
    
    
    // MARK: - API
    
    func fetchUsers() {
        Firestore.firestore().collection("users").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            guard let snapshot = snapshot else { return }
            for document in snapshot.documents {
                let user = User(dictionary: document.data())
                self.users.append(user)
            }
            self.tableView.reloadData()
        }
    }

    
    // MARK: - Helpers
    
    func configureTableView() {
        tableView = UITableView(frame: view.bounds)
        tableView.register(UserCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    func configureSearchBar() {
        navigationItem.searchController = searchBar
        searchBar.searchResultsUpdater = self
        searchBar.obscuresBackgroundDuringPresentation = false
        searchBar.searchBar.placeholder = "Search"
    }
    
    // MARK: - UITableViewDataSource/Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchBar.isActive && searchBar.searchBar.text != "" ? filteredUsers.count : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! UserCell
        cell.user = searchBar.isActive && searchBar.searchBar.text != "" ? filteredUsers[indexPath.row] : nil
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedUser = searchBar.isActive ? filteredUsers[indexPath.row] : users[indexPath.row]
        
        let currentUserUID = Auth.auth().currentUser?.uid ?? ""
        let usersRef = Firestore.firestore().collection("users")

        usersRef.whereField("uid", isEqualTo: currentUserUID).getDocuments { (snapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in snapshot!.documents {
                    let docID = document.documentID
                    usersRef.document(docID).updateData([
                        "searchHistory": FieldValue.arrayUnion([selectedUser.uid])
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            }
        }

        showUserProfile(for: selectedUser)
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        print("[SearchViewController] updateSearchResults")
        print("Search bar text: \(searchController.searchBar.text ?? "")")
        print("Updating search results...")
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }

        let currentUserUID = Auth.auth().currentUser?.uid ?? ""
        print("Current user UID: \(currentUserUID)")

        if searchText.isEmpty {
            filteredUsers = users
        } else {
            filteredUsers = users.filter { user in
                let fullName = "\(user.firstName) \(user.lastName)"
                return fullName.lowercased().contains(searchText)
            }
            print("Filtered users: \(filteredUsers)")
        }

        tableView.reloadData()
    }

    

    func showUserProfile(for user: User) {
        self.searchBar.searchBar.resignFirstResponder()
        let userProfileVC = UserProfileViewController(user: user)
        userProfileVC.user = user
        self.navigationController?.pushViewController(userProfileVC, animated: true)
    }
}

struct User {
    var uid: String
    var firstName: String
    var lastName: String
    var profileImageUrl: String

    init(dictionary: [String: Any]) {
        self.uid = dictionary["uid"] as? String ?? ""
        self.firstName = dictionary["firstname"] as? String ?? ""
        self.lastName = dictionary["lastname"] as? String ?? ""
        self.profileImageUrl = dictionary["profilePictureURL"] as? String ?? ""
    }
}



