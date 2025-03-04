// page controller fixed!
//  HomeViewController.swift
//
//  Created by Yash Thakkar on 8/10/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    
    let recommendationAlgorithm = RecommendationAlgorithm()
    
    var userProfiles: [RecommendationAlgorithm.UserProfile] = []
    
    var likedUserIDs: Set<String> = []
    
    
    var recommendedProfiles: [RecommendationAlgorithm.UserProfile] = []
    
    var postsMapping: [UIPageViewController: [RecommendationAlgorithm.Post]] = [:]
    
    var postsForPageVC: [UIPageViewController: [RecommendationAlgorithm.Post]] = [:]

    var recommendations: [User] = []
    var collectionView: UICollectionView!
    var lastUserCard: UIView?
    let userCardsScrollView = UIScrollView()
    let scrollView = UIScrollView()
    
    var currentIndex: Int = 0
    
    var userCardCount: Int = 0

    private var reportedUserID: String?
    
    var numberOfRecommendedProfiles: Int = 0
    
    
    @IBOutlet var menuTableView: UITableView!
    
    @IBOutlet var containerView: UIView!
    
    private let refreshControl = UIRefreshControl()

    // Rec algorithm
    private let barrier: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private var userCard: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor(red: 1.0, green: 0.341, blue: 0.2, alpha: 1.0)
            view.layer.cornerRadius = 15
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()
        
        private var profileImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 24
            imageView.clipsToBounds = true
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }()
        
        private var nameLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 18)
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        private var imageSlideView: UIPageViewController = {
            let controller = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            return controller
        }()
        
        private var pageControl: UIPageControl = {
            let control = UIPageControl()
            control.currentPageIndicatorTintColor = .blue
            control.pageIndicatorTintColor = .gray
            control.translatesAutoresizingMaskIntoConstraints = false
            return control
        }()
        
    var allRecommendedPosts: [String: [RecommendationAlgorithm.Post]] = [:]
    var currentPosts: [RecommendationAlgorithm.Post] = []
    
    
    var menuButtonOriginalPosition: CGPoint?

    var menu = false
    let screen = UIScreen.main.bounds
    var home = CGAffineTransform()
    
    lazy var menuButton: UIButton = {
        let button = UIButton()
        
        if let originalImage = UIImage(systemName: "line.horizontal.3.circle.fill"),
           let resizedImage = originalImage.resize(to: CGSize(width: 45, height: 45)) {
            var config = UIButton.Configuration.plain()
            config.image = resizedImage
            button.configuration = config
        }
        
        button.backgroundColor = .gray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(toggleMenu), for: .touchUpInside)
        
        button.layer.cornerRadius = 25
        button.clipsToBounds = true
        
        return button
    }()
    
    let menuWrapperView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    

    var options: [option] = [
    
        option(title : "Attracted", segue: "AttractedSegue"),
        option(title : "Share", segue: "ShareSegue"),
        option(title : "Feedback", segue: "FeedbackSegue"),
        option(title : "Sign Out", segue: ""),
    ]
    
    struct option {
        
        var title = String()
        var segue = String()
    }
    
    @objc func toggleMenu() {
        if containerView.transform == home {
            UIView.animate(withDuration: 0.4, animations: {
                self.containerView.layer.cornerRadius = 40
                let x = self.screen.width * 0.5
                let originalTransform = self.containerView.transform
                let scaledTransform = originalTransform.scaledBy(x: 0.8, y: 0.8)
                let scaledAndTranslatedTransform = scaledTransform.translatedBy(x: x, y: 0)
                self.containerView.transform = scaledAndTranslatedTransform
                self.menuWrapperView.transform = scaledAndTranslatedTransform
                self.userCardsScrollView.transform = scaledAndTranslatedTransform
            }) { _ in
                self.menuTableView.isHidden = false
            }
        } else {
            self.menuTableView.isHidden = true

            UIView.animate(withDuration: 0.4, animations: {
                self.containerView.transform = self.home
                self.menuWrapperView.transform = self.home
                self.userCardsScrollView.transform = self.home
                self.containerView.layer.cornerRadius = 0
            })
        }
    }


 
    
    func hideMenu() {
        UIView.animate(withDuration: 0.4) {
            self.containerView.transform = self.home
            self.menuWrapperView.transform = self.home
            self.userCardsScrollView.transform = self.home
            self.containerView.layer.cornerRadius = 0
        }
    }
    
    
    func handleSignOut() {
        do {
            try Auth.auth().signOut()
            
            // Redirect to WelcomeVC
            if let welcomeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeVC") as? WelcomeViewController {
                let navigationController = UINavigationController(rootViewController: welcomeVC)
                navigationController.modalPresentationStyle = .fullScreen
                present(navigationController, animated: true, completion: nil)
            }
        } catch let signOutError {
        }
    }
    
    func shareApp() {
        let text = "Say \"Hi\" to me on UniCenter!"
        let url = URL(string: "https://appstore.com/UniCenter")! //Change with actual link
        let activityItems: [Any] = [text, url]
        
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        
        // Present the share activity view controller
        present(activityVC, animated: true, completion: nil)
    }
    
    
    func openFeedbackEmail() {
        // App version
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown Version"
        
        // iOS Version
        let iOSVersion = UIDevice.current.systemVersion
        
        // Device
        let deviceType = UIDevice.current.model
        
        // Email (from FirebaseAuth)
        let userEmail = Auth.auth().currentUser?.email ?? "Unknown Email"
        
        // Construct email body
        let emailBody = """
        App Version: \(appVersion)
        iOS Version: \(iOSVersion)
        Device: \(deviceType)
        Email: \(userEmail)
        ---------------------------------------------
        Message:
        """
        
        // Construct the mailto URL
        let subject = "UniCenter iOS app Feedback"
        let urlString = "mailto:UniCenterSupport@theandromedacompany.com?subject=\(subject)&body=\(emailBody)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Open Mail app
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup menuTableView
        menuTableView.delegate = self
        menuTableView.dataSource = self
        menuTableView.backgroundColor = .lightGray
        menuTableView.isHidden = true
        home = containerView.transform
                
        // Setup menuWrapperView and menuButton
        view.addSubview(menuWrapperView)
        menuWrapperView.addSubview(menuButton)
        
        userCardsScrollView.isScrollEnabled = true
        
        // Setup barrier
        view.addSubview(barrier)
        
        // Setup userCardsScrollView
        userCardsScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userCardsScrollView)
        
        // Setup collectionView
        setupCollectionView()
        
        // Activate all constraints at once
        NSLayoutConstraint.activate([
            // Constraints for menuWrapperView
            menuWrapperView.topAnchor.constraint(equalTo: containerView.topAnchor),
            menuWrapperView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            menuWrapperView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            menuWrapperView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Constraints for menuButton
            menuButton.topAnchor.constraint(equalTo: menuWrapperView.topAnchor, constant: 50),
            menuButton.leadingAnchor.constraint(equalTo: menuWrapperView.leadingAnchor, constant: 30),
            menuButton.widthAnchor.constraint(equalToConstant: 50),
            menuButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Constraints for barrier
            barrier.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            barrier.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            barrier.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            barrier.heightAnchor.constraint(equalToConstant: 70),
            
            // Constraints for userCardsScrollView
            userCardsScrollView.topAnchor.constraint(equalTo: menuButton.bottomAnchor),
            userCardsScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            userCardsScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            userCardsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        view.bringSubviewToFront(menuButton)
        
        
        // Additional Setup
        view.backgroundColor = .lightGray
        view.bringSubviewToFront(menuWrapperView)
        view.bringSubviewToFront(menuTableView)
        view.layoutIfNeeded()
        menuButtonOriginalPosition = menuButton.frame.origin
        
        // Page view controller setup
        imageSlideView.dataSource = self
        imageSlideView.delegate = self
        setupLayout()
        fetchLikedUserIDs()
        fetchRecommendedProfiles()
        fetchRecommendations()
        
        // Get the number of recommended users and adjust the scrollView's contentSize
        let userCardHeight: CGFloat = 300
        let spacingBetweenCards: CGFloat = 10
        let totalHeight = CGFloat(numberOfRecommendedProfiles) * (userCardHeight + spacingBetweenCards)
        self.userCardsScrollView.contentSize = CGSize(width: self.view.frame.width, height: totalHeight)
        
        view.bringSubviewToFront(userCardsScrollView)
        
        
        refreshControl.addTarget(self, action: #selector(refreshRecommendations(_:)), for: .valueChanged)
        userCardsScrollView.refreshControl = refreshControl
        
    }
    
    func fetchLikedUserIDs() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching liked users: \(error.localizedDescription)")
                return
            }

            if let documents = querySnapshot?.documents, !documents.isEmpty {
                let userData = documents.first?.data()
                self.likedUserIDs = Set(userData?["attractedTo"] as? [String] ?? [])
                print("Liked User IDs fetched: \(self.likedUserIDs)")
            } else {
                print("No user found with UID: \(currentUserID)")
            }
        }
    }



    @objc private func refreshRecommendations(_ sender: UIRefreshControl) {
        // Clear existing data
        clearUserCards()
        recommendedProfiles = []
        allRecommendedPosts = [:]

        // Fetch new recommendations
        fetchRecommendedProfiles { [weak self] in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if self.recommendedProfiles.isEmpty {
                    print("No new recommendations available.")
                } else {
                    for user in self.recommendedProfiles {
                        if let posts = self.allRecommendedPosts[user.uid] {
                            self.updateUIWithRecommendation(user: user, posts: posts)
                        }
                    }
                }
                sender.endRefreshing()
            }
        }
    }


    
    
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 40, height: 400)
        layout.scrollDirection = .vertical
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(RecommendationCell.self, forCellWithReuseIdentifier: "RecommendationCell")
        view.addSubview(collectionView)
        // AutoLayout constraints
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: userCardsScrollView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.heightAnchor.constraint(equalToConstant: 0)
        ])
    }
    
    
    private func fetchRecommendedProfiles(completion: (() -> Void)? = nil) {
        recommendationAlgorithm.fetchAllUsers { [weak self] allUsers in
            guard let self = self, let currentUser = allUsers.first(where: { $0.uid == Auth.auth().currentUser?.uid }) else { return }

            let group = DispatchGroup()
            var usersWithPosts: [RecommendationAlgorithm.UserProfile: [RecommendationAlgorithm.Post]] = [:]

            for user in allUsers {
                group.enter()
                self.recommendationAlgorithm.fetchLatestPostsForUser(user.uid) { posts in
                    DispatchQueue.main.async {
                        if !posts.isEmpty {
                            usersWithPosts[user] = posts
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                let usersHavingPosts = usersWithPosts.keys
                self.recommendedProfiles = self.recommendationAlgorithm.recommendProfiles(for: currentUser, from: Array(usersHavingPosts))

                for user in self.recommendedProfiles {
                    if let posts = usersWithPosts[user] {
                        self.allRecommendedPosts[user.uid] = posts
                        self.updateUIWithRecommendation(user: user, posts: posts)
                    }
                }

                completion?()
            }
        }
    }






    private func clearUserCards() {
        userCardsScrollView.subviews.forEach { $0.removeFromSuperview() }
        lastUserCard = nil
        userCardCount = 0
    }



    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupLayout() {
        userCard.addSubview(profileImageView)
        userCard.addSubview(nameLabel)
        userCard.addSubview(imageSlideView.view)
        userCard.addSubview(pageControl)
        

        let constraints = [
            
            profileImageView.topAnchor.constraint(equalTo: userCard.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: userCard.leadingAnchor, constant: 10),
            profileImageView.widthAnchor.constraint(equalToConstant: 48),
            profileImageView.heightAnchor.constraint(equalToConstant: 48),
            
            nameLabel.topAnchor.constraint(equalTo: userCard.topAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: userCard.trailingAnchor, constant: -10),
            
            imageSlideView.view.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 10),
            imageSlideView.view.leadingAnchor.constraint(equalTo: userCard.leadingAnchor),
            imageSlideView.view.trailingAnchor.constraint(equalTo: userCard.trailingAnchor),
            imageSlideView.view.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -10),
            
            pageControl.bottomAnchor.constraint(equalTo: userCard.bottomAnchor, constant: -10),
            pageControl.centerXAnchor.constraint(equalTo: userCard.centerXAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    
    func fetchRecommendations() {
        recommendationAlgorithm.fetchAllUsers { [weak self] users in
            guard let self = self else { return }
            
            for recommendedUser in users {
                
                self.recommendationAlgorithm.fetchLatestPostsForUser(recommendedUser.uid) { [weak self] posts in
                    guard let self = self else { return }
                    
                    var postImages: [UIImage] = []
                    let dispatchGroup = DispatchGroup()
                    
                    for post in posts {
                        guard let imageUrl = URL(string: post.imagePostURL) else { continue }
                        dispatchGroup.enter()
                        
                        URLSession.shared.dataTask(with: imageUrl) { (data, _, error) in
                            defer { dispatchGroup.leave() }
                            if let data = data, let image = UIImage(data: data) {
                                postImages.append(image)
                            }
                        }.resume()
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self.currentPosts = posts
                        if let firstImage = postImages.first {
                            let firstImageVC = ImageViewController()
                            firstImageVC.image = firstImage
                            
                            self.imageSlideView.setViewControllers([firstImageVC], direction: .forward, animated: false, completion: nil)
                        }
                    }
                }
            }
        }
    }


    
    
    func setupPosts(in pageViewController: UIPageViewController, with posts: [RecommendationAlgorithm.Post]) {
        postsForPageVC[pageViewController] = posts

        if let firstPost = posts.first, let imageVC = createImageViewController(for: firstPost, atIndex: 0) {
            pageViewController.setViewControllers([imageVC], direction: .forward, animated: true, completion: nil)
        }
    }






    
    func updateUIWithRecommendation(user: RecommendationAlgorithm.UserProfile, posts: [RecommendationAlgorithm.Post]) {
        print("[updateUIWithRecommendation] Updating UI for user: \(user.uid) with posts: \(posts.map { $0.imagePostURL })")
        print("[updateUIWithRecommendation] Creating user card for user: \(user.uid)")
        print("UIDs in recommendedProfiles: \(self.recommendedProfiles.map { $0.uid })")
        print("UID for current card: \(user.uid)")
        let userCard = UIView()
        userCard.backgroundColor = UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 0.95)
        userCard.layer.cornerRadius = 20
        userCard.layer.shadowColor = UIColor.black.cgColor
        userCard.layer.shadowOpacity = 0.3
        userCard.layer.shadowOffset = CGSize(width: 0, height: 2)
        userCard.layer.shadowRadius = 4
        userCard.translatesAutoresizingMaskIntoConstraints = false
        userCard.tag = recommendedProfiles.firstIndex(where: { $0.uid == user.uid }) ?? -1
        print("Setting tag for user \(user.uid) as \(userCard.tag)")
        userCardsScrollView.addSubview(userCard)
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 24
        profileImageView.clipsToBounds = true
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        userCard.addSubview(profileImageView)
        
        if let profilePicURL = URL(string: user.profilePictureURL) {
            URLSession.shared.dataTask(with: profilePicURL) { (data, response, error) in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        profileImageView.image = image
                    }
                }
            }.resume()
        }
        
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 20)
        nameLabel.text = "\(user.firstname) \(user.lastname)"
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        userCard.addSubview(nameLabel)
        
        if posts.count > 1 {
            let imageSlideView = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            imageSlideView.dataSource = self
            imageSlideView.delegate = self
            imageSlideView.view.translatesAutoresizingMaskIntoConstraints = false
            userCard.addSubview(imageSlideView.view)
            postsMapping[imageSlideView] = posts
            setupPosts(in: imageSlideView, with: posts)
            
            // Constraints for imageSlideView
            NSLayoutConstraint.activate([
                imageSlideView.view.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 30),
                imageSlideView.view.leadingAnchor.constraint(equalTo: userCard.leadingAnchor),
                imageSlideView.view.trailingAnchor.constraint(equalTo: userCard.trailingAnchor),
                imageSlideView.view.bottomAnchor.constraint(equalTo: userCard.bottomAnchor, constant: -25)
            ])
        } else if let singlePost = posts.first {
            let singleImageView = UIImageView()
            singleImageView.translatesAutoresizingMaskIntoConstraints = false
            singleImageView.contentMode = .scaleAspectFill
            singleImageView.clipsToBounds = true
            userCard.addSubview(singleImageView)
            
            if let singlePostURL = URL(string: singlePost.imagePostURL) {
                URLSession.shared.dataTask(with: singlePostURL) { (data, response, error) in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            singleImageView.image = image
                        }
                    }
                }.resume()
            }
            
            // Constraints for singleImageView
            NSLayoutConstraint.activate([
                singleImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 30),
                singleImageView.leadingAnchor.constraint(equalTo: userCard.leadingAnchor),
                singleImageView.trailingAnchor.constraint(equalTo: userCard.trailingAnchor),
                singleImageView.bottomAnchor.constraint(equalTo: userCard.bottomAnchor, constant: -55)
            ])
        }
        
        
        let heartIconImageView = UIImageView()
        heartIconImageView.image = likedUserIDs.contains(user.uid) ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        heartIconImageView.tintColor = likedUserIDs.contains(user.uid) ? .red : .gray
        heartIconImageView.isUserInteractionEnabled = true
        heartIconImageView.translatesAutoresizingMaskIntoConstraints = false
        userCard.addSubview(heartIconImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(heartIconTapped(_:)))
        heartIconImageView.addGestureRecognizer(tapGesture)

        // Constraints for heartIconImageView
        NSLayoutConstraint.activate([
            heartIconImageView.leadingAnchor.constraint(equalTo: userCard.leadingAnchor, constant: 10),
            heartIconImageView.bottomAnchor.constraint(equalTo: userCard.bottomAnchor, constant: -13),
            heartIconImageView.widthAnchor.constraint(equalToConstant: 30),
            heartIconImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        
        let ellipsisButton = UIButton(type: .system)
        ellipsisButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        ellipsisButton.tintColor = .black // Change color as needed
        ellipsisButton.translatesAutoresizingMaskIntoConstraints = false
        userCard.addSubview(ellipsisButton)
        
        ellipsisButton.tag = userCard.tag

        ellipsisButton.addTarget(self, action: #selector(ellipsisButtonTapped(_:)), for: .touchUpInside)

        // Constraints for ellipsisButton
        NSLayoutConstraint.activate([
            ellipsisButton.topAnchor.constraint(equalTo: userCard.topAnchor, constant: 10),
            ellipsisButton.trailingAnchor.constraint(equalTo: userCard.trailingAnchor, constant: -10),
            ellipsisButton.widthAnchor.constraint(equalToConstant: 30),
            ellipsisButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Constraints for userCard, profileImageView, and nameLabel
        NSLayoutConstraint.activate([
            userCard.centerXAnchor.constraint(equalTo: userCardsScrollView.centerXAnchor),
            userCard.widthAnchor.constraint(equalTo: userCardsScrollView.widthAnchor, multiplier: 0.8),
            userCard.heightAnchor.constraint(equalTo: userCardsScrollView.heightAnchor, multiplier: 0.65),
            profileImageView.topAnchor.constraint(equalTo: userCard.topAnchor, constant: 10),
            profileImageView.leadingAnchor.constraint(equalTo: userCard.leadingAnchor, constant: 10),
            profileImageView.widthAnchor.constraint(equalToConstant: 48),
            profileImageView.heightAnchor.constraint(equalToConstant: 48),
            nameLabel.topAnchor.constraint(equalTo: profileImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: userCard.trailingAnchor, constant: -10)
        ])
        
        if let lastCard = lastUserCard {
              userCard.topAnchor.constraint(equalTo: lastCard.bottomAnchor, constant: 10).isActive = true
          } else {
              userCard.topAnchor.constraint(equalTo: userCardsScrollView.topAnchor, constant: 10).isActive = true
          }

          lastUserCard = userCard
          userCardCount += 1
          let totalHeight = calculateTotalHeight()
          userCardsScrollView.contentSize = CGSize(width: userCardsScrollView.frame.width, height: totalHeight)
    }
    
    
    @objc func ellipsisButtonTapped(_ sender: UIButton) {
        // Create the pane view
        let paneView = UIView(frame: CGRect(x: 0, y: self.view.frame.size.height, width: self.view.frame.size.width, height: 300))
        paneView.backgroundColor = .black
        paneView.layer.cornerRadius = 15
        paneView.tag = 101 // Using a unique tag to identify the pane view later

        // Creating and add the title label
        let titleLabel = UILabel(frame: CGRect(x: 16, y: 16, width: paneView.frame.size.width - 32, height: 30))
        titleLabel.text = "Report a User"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        paneView.addSubview(titleLabel)

        // Creating and add the body label
        let bodyLabel = UILabel(frame: CGRect(x: 16, y: titleLabel.frame.maxY + 10, width: paneView.frame.size.width - 32, height: 60))
        bodyLabel.text = "If a user has posted offensive or inappropriate content, click the button below to report them."
        bodyLabel.textColor = .white
        bodyLabel.font = UIFont.systemFont(ofSize: 16)
        bodyLabel.numberOfLines = 0  // Allows for multiple lines
        bodyLabel.lineBreakMode = .byWordWrapping
        paneView.addSubview(bodyLabel)

        // Creating and add the report button
        let reportButton = UIButton(frame: CGRect(x: 16, y: bodyLabel.frame.maxY + 20, width: paneView.frame.size.width - 32, height: 44))
        reportButton.backgroundColor = .red
        reportButton.layer.cornerRadius = 15
        reportButton.setTitle("Report", for: .normal)
        reportButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside) // Use existing reportButtonTapped function
        paneView.addSubview(reportButton)

        // Creating an overlay button to detect taps outside the pane view
        let overlayButton = UIButton(frame: self.view.bounds)
        overlayButton.backgroundColor = .clear
        overlayButton.tag = 102 // Use a unique tag to identify the overlay button later
        overlayButton.addTarget(self, action: #selector(dismissPane), for: .touchUpInside)
        self.view.addSubview(overlayButton)
        
        let buttonTag = sender.tag
        if buttonTag >= 0 && buttonTag < recommendedProfiles.count {
            let reportedUser = recommendedProfiles[buttonTag]
            reportedUserID = reportedUser.uid // Setting the reportedUserID based on the selected user
        } else {
            print("Error: Button tag is invalid or out of range")
            return
        }

        // Adding the pane view on top of the overlay button
        self.view.addSubview(paneView)

        // Animating the pane view sliding up
        UIView.animate(withDuration: 0.3) {
            paneView.frame.origin.y -= 300
        }
    }

    @objc func dismissPane() {
        if let overlayButton = self.view.viewWithTag(102) {
            overlayButton.removeFromSuperview()
        }
        
        if let paneView = self.view.viewWithTag(101) {
            UIView.animate(withDuration: 0.3, animations: {
                paneView.frame.origin.y += 300
            }) { _ in
                paneView.removeFromSuperview()
            }
        }
    }
    

    
    
    @objc func reportButtonTapped(_ sender: UIButton) {
        dismissPane()

        let buttonTag = sender.tag
        if let uid = reportedUserID {
            presentReportViewController(withUserID: uid)
        } else {
            print("Error: No reported user ID available")
        }
    }



    func presentReportViewController(withUserID uid: String) {
        let reportVC = ReportUserViewController()
        reportVC.reportedUserID = uid
        reportVC.modalPresentationStyle = .fullScreen
        reportVC.onReportSubmission = { [weak self] in
            self?.dismissPane()
            let alertController = UIAlertController(title: "User has been reported", message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            self?.present(alertController, animated: true, completion: nil)
        }
        self.present(reportVC, animated: true, completion: nil)
    }




    
    
    @objc private func heartIconTapped(_ sender: UITapGestureRecognizer) {
        guard let heartIcon = sender.view as? UIImageView,
              let userCard = heartIcon.superview else {
            print("Error: Could not find user card from heart icon")
            return
        }

        let index = userCard.tag
        print("Heart icon tapped for user card with tag: \(index)")

        if index < 0 || index >= recommendedProfiles.count {
            print("Error: UserCard tag is invalid or out of range")
            return
        }

        guard let currentUserID = Auth.auth().currentUser?.uid else {
            print("Error: Current user ID not found")
            return
        }

        let likedUser = recommendedProfiles[index]

        // Toggle the heart icon image and update Firestore
        let isHeartFilled = heartIcon.image == UIImage(systemName: "heart.fill")
        heartIcon.image = isHeartFilled ? UIImage(systemName: "heart") : UIImage(systemName: "heart.fill")
        heartIcon.tintColor = isHeartFilled ? .gray : .red

        // Update local data
        if isHeartFilled {
            likedUserIDs.remove(likedUser.uid)
        } else {
            likedUserIDs.insert(likedUser.uid)
            checkForMutualLike(currentUserID: currentUserID, likedUserID: likedUser.uid)
        }

        // Update Firestore data
        updateFirestoreForLike(currentUserID: currentUserID, likedUserID: likedUser.uid, isHeartFilled: isHeartFilled)

        // Haptic Feedback
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()

        // Popping Animation
        UIView.animate(withDuration: 0.1, animations: {
            heartIcon.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                heartIcon.transform = CGAffineTransform.identity
            }
        })

        if let existingSpeechBlock = findSpeechBlockInView(userCard) {
            dismissSpeechBlock(existingSpeechBlock)
        }

        if !isHeartFilled {
            addSpeechBlockToUserCard(heartIcon, userCard)
        }
    }




    
    private func updateFirestoreForLike(currentUserID: String, likedUserID: String, isHeartFilled: Bool) {
        let userRef = Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID)

        userRef.getDocuments { (snapshot, error) in
            if let snapshot = snapshot, !snapshot.isEmpty {
                let document = snapshot.documents.first
                let docID = document?.documentID ?? ""

                let updateRef = Firestore.firestore().collection("users").document(docID)
                if isHeartFilled {
                    updateRef.updateData(["attractedTo": FieldValue.arrayRemove([likedUserID])])
                } else {
                    updateRef.updateData(["attractedTo": FieldValue.arrayUnion([likedUserID])])
                }
            } else {
                print("Document for the current user does not exist or error: \(error?.localizedDescription ?? "")")
            }
        }
    }

    
    
    
    private func checkForMutualLike(currentUserID: String, likedUserID: String) {
        // Fetching the attractedTo list of the liked user
        Firestore.firestore().collection("users").whereField("uid", isEqualTo: likedUserID).getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let likedUserDocument = documents.first
            let likedUserData = likedUserDocument?.data()

            if let attractedTo = likedUserData?["attractedTo"] as? [String], attractedTo.contains(currentUserID) {
                self?.updateMatchedWith(currentUserID: currentUserID, otherUserID: likedUserID)
                self?.updateMatchedWith(currentUserID: likedUserID, otherUserID: currentUserID)
            }
        }
    }

    private func updateMatchedWith(currentUserID: String, otherUserID: String) {
        Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let currentUserDocument = documents.first
            currentUserDocument?.reference.updateData([
                "matchedWith": FieldValue.arrayUnion([otherUserID])
            ])
        }
    }


    

    private func addSpeechBlockToUserCard(_ heartIcon: UIImageView, _ userCard: UIView) {
        let heartIconFrameInUserCard = heartIcon.superview?.convert(heartIcon.frame, to: userCard) ?? CGRect.zero
        let speechBlockX = heartIconFrameInUserCard.midX - 60 // Adjust to center above the heart
        let speechBlockY = heartIconFrameInUserCard.minY - 40  // Position above the heart

        // Showing Speech Block
        let speechBlock = SpeechBlockView()
        speechBlock.frame = CGRect(x: speechBlockX, y: speechBlockY, width: 200, height: 30)
        speechBlock.alpha = 0
        userCard.addSubview(speechBlock)

        UIView.animate(withDuration: 0.3) {
            speechBlock.alpha = 1
        }

        // Automatically dismissing Speech Block after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismissSpeechBlock(speechBlock)
        }
    }

    private func findSpeechBlockInView(_ view: UIView) -> SpeechBlockView? {
        return view.subviews.first(where: { $0 is SpeechBlockView }) as? SpeechBlockView
    }

    private func dismissSpeechBlock(_ speechBlock: UIView) {
        UIView.animate(withDuration: 0.3, animations: {
            speechBlock.alpha = 0
        }) { _ in
            speechBlock.removeFromSuperview()
        }
    }



    

    private func calculateTotalHeight() -> CGFloat {
        let cardSpacing: CGFloat = 10
        let cardHeight: CGFloat = userCardsScrollView.frame.height * 0.65 + cardSpacing
        return cardHeight * CGFloat(userCardCount) + cardSpacing
    }




    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? ImageViewController,
              let index = imageVC.imageIndex,
              let posts = postsForPageVC[pageViewController],
              index > 0 else {
            return nil
        }
        return createImageViewController(for: posts[index - 1], atIndex: index - 1)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? ImageViewController,
              let index = imageVC.imageIndex,
              let posts = postsForPageVC[pageViewController],
              index < posts.count - 1 else {
            return nil
        }
        return createImageViewController(for: posts[index + 1], atIndex: index + 1)
    }


    
    private func createImageViewController(for post: RecommendationAlgorithm.Post, atIndex index: Int) -> UIViewController? {
        guard let imageUrl = URL(string: post.imagePostURL) else { return nil }
        let imageVC = ImageViewController()
        imageVC.imageIndex = index
        URLSession.shared.dataTask(with: imageUrl) { (data, _, _) in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageVC.image = image
                }
            }
        }.resume()
        return imageVC
    }





    

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return postsMapping[pageViewController]?.count ?? 0
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let currentViewController = pageViewController.viewControllers?.first as? ImageViewController,
              let index = currentViewController.imageIndex else {
            return 0
        }
        return index
    }

    private func getImageViewController(with post: RecommendationAlgorithm.Post, atIndex index: Int) -> UIViewController {
        let imageVC = ImageViewController()
        imageVC.imageIndex = index
        
        if let imageUrl = URL(string: post.imagePostURL) {
            URLSession.shared.dataTask(with: imageUrl) { (data, _, _) in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageVC.image = image
                    }
                }
            }.resume()
        }
        
        return imageVC
    }




    
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell", for: indexPath)
            cell.backgroundColor = .orange
            cell.textLabel?.text = options[indexPath.row].title
            cell.textLabel?.textColor = .black
        
        
        switch options[indexPath.row].title {
            case "Attracted":
                cell.imageView?.image = UIImage(systemName: "heart.fill")
            case "Share":
                cell.imageView?.image = UIImage(systemName: "square.and.arrow.up.fill")
                cell.imageView?.tintColor = UIColor.red
            case "Feedback":
                cell.imageView?.image = UIImage(systemName: "exclamationmark.bubble.fill")
            case "Sign Out":
                cell.imageView?.image = UIImage(systemName: "arrow.right.square.fill")
            default:
                break
            }
        
            tableView.deselectRow(at: indexPath, animated: true)
        
            cell.imageView?.tintColor = .lightGray
        
            return cell
    }
    
    private func presentAttractedToPage() {
        let attractedToVC = AttractedToPage()
        attractedToVC.modalPresentationStyle = .popover
        present(attractedToVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedOption = options[indexPath.row].title

        switch selectedOption {
        case "Attracted":
            presentAttractedToPage()
        case "Sign Out":
            handleSignOut()
        case "Share":
            shareApp()
        case "Feedback":
            openFeedbackEmail()
        default:
            self.performSegue(withIdentifier: options[indexPath.row].segue, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension UITableView {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
}

extension UIScrollView {
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }
}

    

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecommendationCell", for: indexPath) as! RecommendationCell
        return cell
    }
}

class RecommendationCell: UICollectionViewCell {
}
    
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}


