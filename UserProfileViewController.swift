// UserProfileVC
import UIKit
import Firebase

class UserProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var user: User?
    var collectionView: UICollectionView!
    var profilePicImage: UIImageView!
    var userNameLabel: UILabel!
    var userPosts: [UIImage] = []
    var userImages: [UIImage?] = []
    var likedUserIDs: Set<String> = []
    var overlayCenterImageView: UIImageView!
    var overlayTopImageView: UIImageView!
    var overlayBottomImageView: UIImageView!
    var visualEffectView: UIVisualEffectView!
    var backgroundView: UIView?
    var imagePositionSlider: UISlider!
    var backButton: UIButton!
    var sliderTrackView: UIView!
    var sliderIndicatorView: UIView!
    var sliderTrackLayer: CAShapeLayer?
    var sliderIndicatorLayer: CAShapeLayer?
    let sliderWidth: CGFloat = 3.0
    let sliderHeight: CGFloat = 100.0
    let indicatorHeight: CGFloat = 10.0
    var sliderY: CGFloat = 0.0
    var swipeUpGesture: UISwipeGestureRecognizer?
    var swipeDownGesture: UISwipeGestureRecognizer?
    var currentImageIndex: Int?
    
    
    var refreshControl = UIRefreshControl()

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        displayOverlayImages(for: indexPath.row)
    }
    
    let heartButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "heart"), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(heartButtonTapped), for: .touchUpInside)
        return button
    }()
    
    func displayOverlayImages(for index: Int) {
        print("[DEBUG] displayOverlayImages triggered for index: \(index)")
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        let tappedImage = userPosts[index]
        currentImageIndex = index
        
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
        
        let blurEffect = UIBlurEffect(style: .dark)
        visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = view.bounds
        
        backgroundView = UIView(frame: view.bounds)
        backgroundView!.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        view.addSubview(backgroundView!)
        view.addSubview(visualEffectView)
        
        setupSlider()
        
        let imageViewWidth = view.bounds.width * 0.9
        let imageViewHeight = imageViewWidth * 0.6
        let imageViewX = (view.bounds.width - imageViewWidth) / 2
        let imageViewY = (view.bounds.height - imageViewHeight) / 2
        

        overlayCenterImageView = UIImageView(image: userPosts[index])
        overlayCenterImageView.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewWidth, height: imageViewHeight)
        overlayCenterImageView.contentMode = .scaleAspectFill
        overlayCenterImageView.clipsToBounds = true
        overlayCenterImageView.layer.cornerRadius = 15
        overlayCenterImageView.layer.borderWidth = 3.0
        overlayCenterImageView.layer.borderColor = UIColor.white.cgColor
        view.addSubview(overlayCenterImageView)

        if index > 0 {
            self.overlayTopImageView = UIImageView(image: userPosts[index - 1])
            self.overlayTopImageView.frame = CGRect(x: imageViewX + (imageViewWidth * 0.1), y: imageViewY - imageViewHeight * 0.8 - 20, width: imageViewWidth * 0.8, height: imageViewHeight * 0.8)
            self.overlayTopImageView.contentMode = .scaleAspectFill
            self.overlayTopImageView.clipsToBounds = true
            self.overlayTopImageView.layer.cornerRadius = 15
            self.overlayTopImageView.alpha = 0.5 // Dimming effect
            self.view.addSubview(self.overlayTopImageView)
        }

        if index < userPosts.count - 1 {
            self.overlayBottomImageView = UIImageView(image: userPosts[index + 1])
            self.overlayBottomImageView.frame = CGRect(x: imageViewX + (imageViewWidth * 0.1), y: imageViewY + imageViewHeight + 20, width: imageViewWidth * 0.8, height: imageViewHeight * 0.8)
            self.overlayBottomImageView.contentMode = .scaleAspectFill
            self.overlayBottomImageView.clipsToBounds = true
            self.overlayBottomImageView.layer.cornerRadius = 15
            self.overlayBottomImageView.alpha = 0.5 // Dimming effect
            self.view.addSubview(self.overlayBottomImageView)
        }

        
        backButton = UIButton(frame: CGRect(x: 20, y: 70, width: 50, height: 50))
        backButton.setImage(UIImage(systemName: "arrowshape.left.fill"), for: .normal)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        backButton.layer.cornerRadius = backButton.frame.width / 2
        backButton.addTarget(self, action: #selector(closeOverlay), for: .touchUpInside)
        view.addSubview(backButton)
        
        swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleOverlaySwipeUp))
        swipeUpGesture?.direction = .up
        view.addGestureRecognizer(swipeUpGesture!)
        
        swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleOverlaySwipeDown))
        swipeDownGesture?.direction = .down
        view.addGestureRecognizer(swipeDownGesture!)
    }
    
    
    
    @objc func handleOverlaySwipeUp() {
        print("[DEBUG] handleOverlaySwipeUp triggered")
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()

        guard let currentImage = overlayCenterImageView.image, let currentIndex = userPosts.firstIndex(of: currentImage), currentIndex < userPosts.count - 1 else {
            return
        }

        if let _ = overlayTopImageView, let _ = overlayCenterImageView {
            overlayTopImageView.image = overlayCenterImageView.image
        }

        overlayCenterImageView.image = userPosts[safe: currentIndex + 1]
        
        if let _ = overlayBottomImageView {
            overlayBottomImageView.image = userPosts[safe: currentIndex + 2]
        }
    }

    @objc func handleOverlaySwipeDown() {
        print("[DEBUG] handleOverlaySwipeDown triggered")
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()

        guard let currentImage = overlayCenterImageView.image, let currentIndex = userPosts.firstIndex(of: currentImage), currentIndex > 0 else {
            return
        }

        if let _ = overlayBottomImageView, let _ = overlayCenterImageView {
            overlayBottomImageView.image = overlayCenterImageView.image
        }

        overlayCenterImageView.image = userPosts[safe: currentIndex - 1]

        if let _ = overlayTopImageView {
            overlayTopImageView.image = userPosts[safe: currentIndex - 2]
        }
    }


    func adjustSliderPosition() {
        let trackHeight = sliderTrackView.bounds.height
        let indicatorHeight: CGFloat = trackHeight * 0.1
        if let currentImageIndex = currentImageIndex {
            let positionPercentage = CGFloat(currentImageIndex) / CGFloat(userPosts.count - 1)
            let offsetY = (trackHeight - indicatorHeight) * positionPercentage
            sliderIndicatorView.frame.origin.y = sliderTrackView.frame.origin.y + offsetY
        }
    }


    
    
    func setupSlider() {
        let trackWidth: CGFloat = 4
        let trackHeight: CGFloat = (view.bounds.height / 3) * 0.66
        let trackX = view.bounds.width - 20
        let trackY = (view.bounds.height - trackHeight) / 2
        let trackRect = CGRect(x: trackX, y: trackY, width: trackWidth, height: trackHeight)
        
        sliderTrackView = UIView(frame: trackRect)
        sliderTrackView.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        sliderTrackView.layer.cornerRadius = trackWidth / 2
        view.addSubview(sliderTrackView)
        
        let indicatorHeight: CGFloat = trackHeight * 0.1
        if let currentImageIndex = currentImageIndex {
            let positionPercentage = CGFloat(currentImageIndex) / CGFloat(userPosts.count - 1)
            let offsetY = (trackRect.height - indicatorHeight) * positionPercentage
            let indicatorRect = CGRect(x: trackX, y: trackY + offsetY, width: trackWidth, height: indicatorHeight)
            
            sliderIndicatorView = UIView(frame: indicatorRect)
            sliderIndicatorView.backgroundColor = UIColor.green
            sliderIndicatorView.layer.cornerRadius = trackWidth / 2
            view.addSubview(sliderIndicatorView)
            view.bringSubviewToFront(sliderIndicatorView)
        }
    }

    
    @objc func closeOverlay() {
        overlayCenterImageView.removeFromSuperview()
        overlayTopImageView?.removeFromSuperview()
        overlayBottomImageView?.removeFromSuperview()
        sliderTrackView?.removeFromSuperview()
        sliderIndicatorView.removeFromSuperview()
        backButton.removeFromSuperview()
        
        backgroundView?.removeFromSuperview()
        visualEffectView?.removeFromSuperview()
        
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = false
        
        self.navigationItem.hidesBackButton = false
        self.navigationItem.leftBarButtonItem = nil
        
        
    }
    
    @objc func refreshData() {
        fetchUserPosts()
    }
    
    func image(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, _, _) in
            if let data = data {
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        let profilePicSize: CGFloat = 150
        profilePicImage = UIImageView(frame: CGRect(x: 0, y: 80, width: profilePicSize, height: profilePicSize))
        profilePicImage.center.x = view.center.x
        profilePicImage.layer.cornerRadius = profilePicSize / 2
        profilePicImage.clipsToBounds = true
        profilePicImage.contentMode = .scaleAspectFill
        if let imageUrlString = user?.profileImageUrl, let imageUrl = URL(string: imageUrlString) {
            URLSession.shared.dataTask(with: imageUrl) { (data, _, _) in
                if let data = data {
                    DispatchQueue.main.async {
                        self.profilePicImage.image = UIImage(data: data)
                    }
                }
            }.resume()
        }
        view.addSubview(profilePicImage)
        
        userNameLabel = UILabel(frame: CGRect(x: 20, y: profilePicImage.frame.maxY + 15, width: view.frame.width - 40, height: 30))
        userNameLabel.text = "\(user?.firstName ?? "") \(user?.lastName ?? "")"
        userNameLabel.textAlignment = .center
        userNameLabel.textColor = .gray
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        userNameLabel.sizeToFit()
        userNameLabel.center.x = view.center.x
        view.addSubview(userNameLabel)
        
        heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
        view.addSubview(heartButton)
        
        NSLayoutConstraint.activate([
            heartButton.leadingAnchor.constraint(equalTo: userNameLabel.trailingAnchor, constant: 8),
            heartButton.centerYAnchor.constraint(equalTo: userNameLabel.centerYAnchor),
            heartButton.widthAnchor.constraint(equalToConstant: 30),
            heartButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        collectionView = UICollectionView(frame: CGRect(x: 0, y: userNameLabel.frame.maxY + 10, width: view.frame.width, height: view.frame.height - (userNameLabel.frame.maxY + 10)), collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true

        view.addSubview(collectionView)
        
        view.addSubview(heartButton)
        updateHeartButtonState()
        
        fetchUserPosts()
    }
    
    
    func updateHeartButtonState() {
        let isLiked = likedUserIDs.contains(user?.uid ?? "")
        heartButton.setImage(isLiked ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart"), for: .normal)
    }


    @objc func heartButtonTapped() {
        guard let profileUserID = user?.uid, let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let isLiked = likedUserIDs.contains(profileUserID)
        if isLiked {
            likedUserIDs.remove(profileUserID)
            heartButton.setImage(UIImage(systemName: "heart"), for: .normal)
            updateFirestoreForLike(currentUserID: currentUserID, likedUserID: profileUserID, isLiked: false)
        } else {
            likedUserIDs.insert(profileUserID)
            heartButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            updateFirestoreForLike(currentUserID: currentUserID, likedUserID: profileUserID, isLiked: true)
            checkForMutualLike(currentUserID: currentUserID, likedUserID: profileUserID)
        }
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()
    }
    
    private func checkForMutualLike(currentUserID: String, likedUserID: String) {
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

    private func updateFirestoreForLike(currentUserID: String, likedUserID: String, isLiked: Bool) {
        let usersRef = Firestore.firestore().collection("users")
        usersRef.whereField("uid", isEqualTo: currentUserID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                guard let snapshot = snapshot, !snapshot.documents.isEmpty else {
                    print("No documents found")
                    return
                }
                let document = snapshot.documents.first
                let docID = document?.documentID ?? ""
                let userDocRef = Firestore.firestore().collection("users").document(docID)

                if isLiked {
                    userDocRef.updateData(["attractedTo": FieldValue.arrayUnion([likedUserID])])
                } else {
                    userDocRef.updateData(["attractedTo": FieldValue.arrayRemove([likedUserID])])
                }
            }
        }
    }


    
    
    
    func addToAttractedTo(userID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("No documents found for the current user")
                return
            }

            let docID = document.documentID
            Firestore.firestore().collection("users").document(docID).updateData([
                "attractedTo": FieldValue.arrayUnion([userID])
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                } else {
                    print("Document successfully updated to add like")
                }
            }
        }
    }

    func removeFromAttractedTo(userID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                return
            }

            guard let document = snapshot?.documents.first else {
                print("No documents found for the current user")
                return
            }

            let docID = document.documentID
            Firestore.firestore().collection("users").document(docID).updateData([
                "attractedTo": FieldValue.arrayRemove([userID])
            ]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                } else {
                    print("Document successfully updated to remove like")
                }
            }
        }
    }


    
    
    func fetchUserPosts() {
        guard let userUID = user?.uid else { return }
        Firestore.firestore().collection("posts")
            .whereField("uid", isEqualTo: userUID)
            .order(by: "postTime", descending: true)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error fetching posts: \(error)")
                    return
                }

                let group = DispatchGroup()

                var orderedImageURLs: [String] = []
                var imageDict: [String: UIImage] = [:]

                for document in snapshot!.documents {
                    let data = document.data()
                    if let imageURL = data["imagePostURL"] as? String {
                        orderedImageURLs.append(imageURL)
                        if let url = URL(string: imageURL) {
                            group.enter() // Enter group for each URL session task
                            URLSession.shared.dataTask(with: url) { (data, _, _) in
                                if let data = data, let image = UIImage(data: data) {
                                    imageDict[imageURL] = image
                                }
                                group.leave()
                            }.resume()
                        }
                    }
                }

                group.notify(queue: .main) {
                    self.userPosts = orderedImageURLs.compactMap { imageDict[$0] }
                    self.collectionView.reloadData()
                }
            }
        self.refreshControl.endRefreshing()
    }


    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userPosts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let postImage = userPosts[indexPath.item]
        let imageView = UIImageView(frame: cell.contentView.bounds)
        imageView.image = postImage
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        cell.contentView.addSubview(imageView)

        return cell

    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 4) / 3
        return CGSize(width: width, height: width)
    }
    
}


extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

