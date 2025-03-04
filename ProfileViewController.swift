// ProfileViewController.swift Everything works just one minor issue with reenter from the ends
//
//  Created by Yash Thakkar on 8/7/23.
//

import UIKit
import Photos
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import FirebaseAppCheck
import AVKit
import TOCropViewController

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    struct UserPost {
        var image: UIImage
        var documentID: String
        var imagePath: String
    }
    
    var userPosts: [UserPost] = []
    var collectionView: UICollectionView!
    
    
    var userNameLabel: UILabel!
    var editProfileButton: UIButton!
    var addPhotoButton: UIButton!
    
    
    
    var overlayCenterImageView: UIImageView!
    var overlayTopImageView: UIImageView!
    var overlayBottomImageView: UIImageView!
    var closeButton: UIButton!
    var visualEffectView: UIVisualEffectView!
    var backgroundView: UIView?

    var imagePositionSlider: UISlider!


    
    var backButton: UIButton!
    var deleteButton: UIButton!
    
    var refreshControl = UIRefreshControl()
    
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

    
    
    let screenWidth = UIScreen.main.bounds.width
    
    private var isUpdatingProfileImage = false
    
    @IBOutlet weak var profilePicImage: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    func updateProfilePicture(with data: Data) {
        DispatchQueue.main.async {
            self.profilePicImage.image = UIImage(data: data)
        }
    }
    
    
    func setupSlider() {
        let sliderWidth: CGFloat = 4
        let sliderHeight: CGFloat = view.bounds.height / 3
        let sliderX = view.bounds.width - 20
        sliderY = (view.bounds.height - sliderHeight) / 2

        let trackRect = CGRect(x: sliderX, y: sliderY, width: sliderWidth, height: sliderHeight)

        let indicatorHeight: CGFloat = sliderHeight * 0.1
        
        if let overlayImage = overlayCenterImageView?.image, let currentImageIndex = userPosts.firstIndex(where: { $0.image == overlayImage }) {

            let positionPercentage = CGFloat(currentImageIndex) / CGFloat(userPosts.count - 1)
            let offsetY = (trackRect.height - indicatorHeight) * positionPercentage
            let indicatorRect = CGRect(x: sliderX, y: sliderY + offsetY, width: sliderWidth, height: indicatorHeight)

            // Creating ndicator view
            sliderIndicatorView = UIView()
                sliderIndicatorView.frame = CGRect(x: sliderX, y: sliderY, width: 4, height: indicatorHeight)
                sliderIndicatorView.backgroundColor = UIColor.green
                view.addSubview(sliderIndicatorView)
                view.bringSubviewToFront(sliderIndicatorView)
            
        } else {
            print("Error: Image not found in userPosts or overlayCenterImageView is nil.")
        }
    }







    func updateSliderPosition(forImageAtIndex index: Int) {
        let totalImages = userPosts.count
        if totalImages <= 1 { return }
        
        let positionPercentage = CGFloat(index) / CGFloat(totalImages - 1)
        let maxOffset = sliderHeight - indicatorHeight
        let offsetY = positionPercentage * maxOffset
        
        if let sliderIndicator = sliderIndicatorView {
                sliderIndicator.frame.origin.y = sliderY + offsetY
            } else {
                print("Error: sliderIndicatorView is nil.")
            }
    }





    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.profilePicImage.image = UIImage(named: "your_test_image_name")
        profilePicImage.isUserInteractionEnabled = true
        profilePicImage.contentMode = .scaleAspectFill
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(uploadProfilePhotoTapped(tapGestureRecognizer:)))
        profilePicImage.addGestureRecognizer(tapGestureRecognizer)
        
        profilePicImage.backgroundColor = .lightGray
        profilePicImage.layer.masksToBounds = true
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        
        
        userNameLabel = UILabel()
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        userNameLabel.textAlignment = .center
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        userNameLabel.textColor = .gray
        view.addSubview(userNameLabel)
        
        
        editProfileButton = UIButton()
        editProfileButton.setTitle("Edit Profile", for: .normal)
        editProfileButton.backgroundColor = .gray
        editProfileButton.layer.cornerRadius = 15
        editProfileButton.addTarget(self, action: #selector(editProfileButtonTapped), for: .touchUpInside)
        editProfileButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(editProfileButton)
        
        addPhotoButton = UIButton()
        addPhotoButton.setTitle("Add", for: .normal)
        addPhotoButton.backgroundColor = .gray
        addPhotoButton.layer.cornerRadius = 15
        addPhotoButton.addTarget(self, action: #selector(addPhotoButtonTapped), for: .touchUpInside)
        addPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addPhotoButton)
        
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth/3, height: screenWidth/3)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        if let safeCollectionView = collectionView {
            safeCollectionView.bounces = false
        }



        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .systemBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            userNameLabel.topAnchor.constraint(equalTo: profilePicImage.bottomAnchor, constant: 8),
            userNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            userNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            
            editProfileButton.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 10),
            editProfileButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            editProfileButton.trailingAnchor.constraint(equalTo: addPhotoButton.leadingAnchor, constant: -40),
            editProfileButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            editProfileButton.heightAnchor.constraint(equalToConstant: 40),

            addPhotoButton.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 10),
            addPhotoButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            addPhotoButton.heightAnchor.constraint(equalToConstant: 40),
            addPhotoButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            
            
            collectionView.topAnchor.constraint(equalTo: addPhotoButton.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        fetchUserPosts()
        
        if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                let userRef = db.collection("users").whereField("uid", isEqualTo: uid)

                userRef.getDocuments { (querySnapshot, error) in
                    guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                        print("No documents found for this user or error: \(error?.localizedDescription ?? "unknown error")")
                        return
                    }
                    
                    let userData = documents[0].data()
                    let profilePictureURLString = userData["profilePictureURL"] as? String ?? ""
                    let firstName = userData["firstname"] as? String ?? ""
                    let lastName = userData["lastname"] as? String ?? ""
                    
                    DispatchQueue.main.async {
                        self.userNameLabel.text = "\(firstName) \(lastName)"
                    }

                    guard let profilePictureURL = URL(string: profilePictureURLString) else {
                        print("Profile Picture URL is not valid.")
                        return
                    }

                    URLSession.shared.dataTask(with: profilePictureURL) { (data, response, error) in
                        guard let data = data else {
                            print("Unable to fetch image data from URL: \(error?.localizedDescription ?? "unknown error")")
                            return
                        }

                        DispatchQueue.main.async {
                            self.profilePicImage.image = UIImage(data: data)
                        }
                    }.resume()
                }
            } else {
                print("User is not logged in or userId is nil")
            }
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "cell")
        
        
        refreshControl.addTarget(self, action: #selector(fetchUserPosts), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        }
    
    
    
    
    @objc func fetchUserPosts() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in or userId is nil")
            return
        }

        let db = Firestore.firestore()
        let postsRef = db.collection("posts").whereField("uid", isEqualTo: uid).order(by: "postTime", descending: true)

        postsRef.getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting user's posts: \(error)")
                return
            }

            let group = DispatchGroup()

            var orderedImageURLs: [String] = []
            var imageDict: [String: UserPost] = [:]

            for document in querySnapshot!.documents {
                let data = document.data()
                if let imageURL = data["imagePostURL"] as? String {
                    orderedImageURLs.append(imageURL)
                    if let url = URL(string: imageURL) {
                        group.enter()
                        URLSession.shared.dataTask(with: url) { (data, _, _) in
                            if let data = data, let image = UIImage(data: data) {
                                let post = UserPost(image: image, documentID: document.documentID, imagePath: imageURL)
                                imageDict[imageURL] = post
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


    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    func postImageToFirebase(image: UIImage) {
        guard let currentUserUID = Auth.auth().currentUser?.uid else {
            print("No user logged in!")
            return
        }
        let storageRef = Storage.storage().reference().child("UserPosts/\(UUID().uuidString).jpg")
        
        if let uploadData = image.jpegData(compressionQuality: 0.8) {
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if error != nil {
                    print("Failed to upload image:", error!)
                    return
                }
                storageRef.downloadURL { (url, error) in
                    if let downloadURL = url?.absoluteString {
                        let db = Firestore.firestore()
                        let postDocument = db.collection("posts").document()
                        let postData: [String: Any] = [
                            "postTime": Timestamp(date: Date()),
                            "imagePostURL": downloadURL,
                            "uid": currentUserUID
                        ]
                        
                        postDocument.setData(postData) { error in
                            if let error = error {
                                print("Error writing document: \(error)")
                            } else {
                                print("Document successfully written!")
                                self.userPosts.insert(UserPost(image: image, documentID: postDocument.documentID, imagePath: ""), at: 0)
                                self.collectionView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }


    
    
    @objc func handleImageTap(_ sender: UITapGestureRecognizer) {
        if let imageView = sender.view as? UIImageView {
            let enlargedImageVC = EnlargedPhotoViewController()
            enlargedImageVC.selectedImage = imageView.image
            enlargedImageVC.profileImage = self.profilePicImage.image
            enlargedImageVC.userName = userNameLabel.text
            self.present(enlargedImageVC, animated: true, completion: nil)
            
            
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
                feedbackGenerator.prepare()
                feedbackGenerator.impactOccurred()
        }
    }
    
    
    

    @objc func handleOverlaySwipeUp() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()

        if let currentImage = overlayCenterImageView.image,
           let index = userPosts.firstIndex(where: { $0.image == currentImage }),
           index < userPosts.count - 1 {
            
            let previousCenterImage = overlayCenterImageView.image
            
            overlayCenterImageView.image = userPosts[index + 1].image

            if overlayTopImageView == nil {
                let imageViewWidth = view.bounds.width * 0.9
                let imageViewHeight = imageViewWidth * 0.6
                let imageViewX = (view.bounds.width - imageViewWidth) / 2
                let topImageY = ((view.bounds.height - imageViewHeight) / 2 - 20) - (imageViewHeight * 0.8)
                overlayTopImageView = UIImageView(frame: CGRect(x: imageViewX + (imageViewWidth * 0.1),
                                                                y: topImageY,
                                                                width: imageViewWidth * 0.8,
                                                                height: imageViewHeight * 0.8))
                overlayTopImageView.contentMode = .scaleAspectFill
                overlayTopImageView.clipsToBounds = true
                overlayTopImageView.layer.cornerRadius = 12
                overlayTopImageView.alpha = 0.6
                view.addSubview(overlayTopImageView)
            }
            overlayTopImageView.image = previousCenterImage
            
            if let overlayBottomImageView = overlayBottomImageView {
                overlayBottomImageView.image = (index + 2 < userPosts.count) ? userPosts[index + 2].image : nil
            }
            
            let newSliderY = sliderTrackView.frame.origin.y + CGFloat(index + 1) * ((view.bounds.height / 3) * 0.66 / CGFloat(userPosts.count))
            let maxSliderY = sliderTrackView.frame.origin.y + (view.bounds.height / 3) * 0.66 - 20.0
            sliderIndicatorView.frame.origin.y = min(newSliderY, maxSliderY)
        }
    }



    @objc func handleOverlaySwipeDown() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.impactOccurred()

        if let currentImage = overlayCenterImageView.image,
           let index = userPosts.firstIndex(where: { $0.image == currentImage }),
           index > 0 {
            
            let previousCenterImage = overlayCenterImageView.image
            
            // Update overlayCenterImageView
            overlayCenterImageView.image = userPosts[index - 1].image

            // Checking if overlayBottomImageView exists
            if overlayBottomImageView == nil {
                let imageViewWidth = view.bounds.width * 0.9
                let imageViewHeight = imageViewWidth * 0.6
                let imageViewX = (view.bounds.width - imageViewWidth) / 2
                let bottomImageY = ((view.bounds.height + imageViewHeight) / 2) + 20
                overlayBottomImageView = UIImageView(frame: CGRect(x: imageViewX + (imageViewWidth * 0.1),
                                                                   y: bottomImageY,
                                                                   width: imageViewWidth * 0.8,
                                                                   height: imageViewHeight * 0.8))
                overlayBottomImageView.contentMode = .scaleAspectFill
                overlayBottomImageView.clipsToBounds = true
                overlayBottomImageView.layer.cornerRadius = 12
                overlayBottomImageView.alpha = 0.6
                view.addSubview(overlayBottomImageView)
            }
            overlayBottomImageView.image = previousCenterImage
            
            // Check if overlayTopImageView exists
            if let overlayTopImageView = overlayTopImageView {
                overlayTopImageView.image = (index - 2 >= 0) ? userPosts[index - 2].image : nil
            }
            
            // Adjusting the slider's position
            let newSliderY = sliderTrackView.frame.origin.y + CGFloat(index - 1) * ((view.bounds.height / 3) * 0.66 / CGFloat(userPosts.count))
            sliderIndicatorView.frame.origin.y = newSliderY
        }
    }

    
    func deletePost(_ post: UserPost) {
        // Delete from Firestore
        let db = Firestore.firestore()
        db.collection("posts").document(post.documentID).delete { [weak self] (error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error deleting post: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                if let index = self.userPosts.firstIndex(where: { $0.documentID == post.documentID }) {
                    // Remove the post from the userPosts array
                    self.userPosts.remove(at: index)
                    // Perform the deletion of the cell with an animation
                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                    }, completion: nil)
                }
                
                // Alert to show that the post was successfully deleted
                let alert = UIAlertController(title: "Post Deleted", message: "Please go back and refresh your profile to see the changes", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                print("Post successfully deleted from Firestore!")
            }
        }
        
        // Delete from Firebase Storage
        let storage = Storage.storage()
        let storageRef = storage.reference().child(post.imagePath)
        storageRef.delete { (error) in
            if let error = error {
                print("Error deleting image from Firebase Storage: \(error)")
                return
            }
            print("Image successfully deleted from Firebase Storage!")
        }
    }

    
    
    @objc func handleDeleteTapped() {
        let alert = UIAlertController(title: "Delete Post", message: "Do you want to delete this image?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            // Identify the currently displayed image
            if let currentImage = self.overlayCenterImageView.image,
               let userPostToDelete = self.userPosts.first(where: { $0.image == currentImage }) {
               
                // Delete the post
                self.deletePost(userPostToDelete)
                
                // Remove the post from the userPosts array
                if let index = self.userPosts.firstIndex(where: { $0.documentID == userPostToDelete.documentID }) {
                    self.userPosts.remove(at: index)
                }
                
                
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    
    @objc func editProfileButtonTapped() {
        let editProfileVC = EditProfileViewController()
        editProfileVC.modalPresentationStyle = .popover
        present(editProfileVC, animated: true, completion: nil)
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
        }
    
    

    @objc func addPhotoButtonTapped() {
        isUpdatingProfileImage = false
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.dismiss(animated: true) {
                
if UIImagePickerController.isSourceTypeAvailable(.camera) {
    let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch cameraAuthorizationStatus {
    case .authorized:
        self.imagePicker.sourceType = .camera
        self.present(self.imagePicker, animated: true, completion: nil)
    case .denied, .restricted:
        let alert = UIAlertController(title: "Access Denied",
                                      message: "To access the camera, please update your app settings.",
                                      preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    case .notDetermined:
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    self.imagePicker.sourceType = .camera
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Access Denied",
                                                  message: "To access the camera, please update your app settings.",
                                                  preferredStyle: .alert)
                    let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alert.addAction(settingsAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    default:
        print("Camera not available on this device.")
    }
} else {
    print("Camera not available on this device.")
}

            }
        })
        
        let cameraImage = UIImage(systemName: "camera")?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10))
        cameraAction.setValue(cameraImage, forKey: "image")
        actionSheet.addAction(cameraAction)
        
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.dismiss(animated: true) {
                let status = PHPhotoLibrary.authorizationStatus()
if status == .authorized {
    self.imagePicker.sourceType = .photoLibrary
    self.present(self.imagePicker, animated: true, completion: nil)
} else {
    
let alert = UIAlertController(title: "Access Denied",
                              message: "To access your photos, please update your app settings.",
                              preferredStyle: .alert)
let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
alert.addAction(settingsAction)
alert.addAction(cancelAction)
self.present(alert, animated: true, completion: nil)

}
            }
        })
        
        let libraryImage = UIImage(systemName: "photo")?.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10))
        photoLibraryAction.setValue(libraryImage, forKey: "image")
        actionSheet.addAction(photoLibraryAction)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.addPhotoButton
            popoverController.sourceRect = CGRect(x: self.addPhotoButton.bounds.midX, y: self.addPhotoButton.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        self.present(actionSheet, animated: true, completion: nil)
    }


    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profilePicImage.layer.cornerRadius = profilePicImage.frame.height / 2
    }
    
    @objc func uploadProfilePhotoTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        
        isUpdatingProfileImage = true
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            // Request access
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    // Access has been granted, present the image picker
                    DispatchQueue.main.async {
                        let status = PHPhotoLibrary.authorizationStatus()
if status == .authorized {
    self.imagePicker.sourceType = .photoLibrary
    self.present(self.imagePicker, animated: true, completion: nil)
} else {
    
let alert = UIAlertController(title: "Access Denied",
                              message: "To access your photos, please update your app settings.",
                              preferredStyle: .alert)
let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
alert.addAction(settingsAction)
alert.addAction(cancelAction)
self.present(alert, animated: true, completion: nil)

}
                    }
                } else {

                }
            }
        } else if status == .authorized {
            // Access has already been granted, present the image picker
            DispatchQueue.main.async {
                self.imagePicker.sourceType = .photoLibrary
                self.imagePicker.accessibilityLabel = "profile"
                self.present(self.imagePicker, animated: true, completion: nil)
            }
        } else {

        }
    }
}


class ImageCell: UICollectionViewCell {
    var imageView: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView = UIImageView(frame: contentView.bounds)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }

        picker.dismiss(animated: true) {
            self.presentCropViewController(image: image)
        }
    }
    
    func presentCropViewController(image: UIImage) {
        let cropViewController = TOCropViewController(croppingStyle: .default, image: image)
        let aspectRatio = CGSize(width: 1, height: 1)
        cropViewController.customAspectRatio = aspectRatio
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.delegate = self
        self.present(cropViewController, animated: true, completion: nil)
    }

    func handleImageActions(pickedImage: UIImage) {
        if isUpdatingProfileImage {
            uploadProfileImage(pickedImage: pickedImage)
        } else {
            postImageToFirebase(image: pickedImage)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return userPosts.count
        }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ImageCell
        cell.imageView.image = userPosts[indexPath.item].image

            return cell
    }
    
    
    // New for Stack View
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        displayOverlayImages(for: indexPath.row)
    }
    
    
    func displayOverlayImages(for index: Int) {
        
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()
        
        let tappedImage = userPosts[index]
        
        // Add blur effect to background
        let blurEffect = UIBlurEffect(style: .dark)
        visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.frame = view.bounds
        
        // Semi-Transparent Background View
        backgroundView = UIView(frame: view.bounds)
        backgroundView!.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        view.addSubview(backgroundView!)
        view.addSubview(visualEffectView)
        
        setupSlider()

        // Setup Back Button
        backButton = UIButton(frame: CGRect(x: 20, y: 70, width: 50, height: 50))
        backButton.setImage(UIImage(systemName: "arrowshape.left.fill"), for: .normal)
        backButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 22)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        backButton.layer.cornerRadius = backButton.frame.width / 2
        backButton.addTarget(self, action: #selector(closeOverlay), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Initialize imagePositionSlider without adding it to the view
        if imagePositionSlider == nil {
            imagePositionSlider = UISlider()
            imagePositionSlider.minimumValue = 0
            imagePositionSlider.maximumValue = Float(userPosts.count - 1)
        }
        imagePositionSlider.value = Float(index) // Set its value according to the current image index
        
        // Calculate the position of the sliderIndicatorView based on the current image index
        let sliderTrackHeight: CGFloat = (view.bounds.height / 3) * 0.66  // Updated track height
        let sliderTrackWidth: CGFloat = 4
        let sliderTrackX: CGFloat = view.bounds.width - 20
        let sliderTrackY: CGFloat = (view.bounds.height - sliderTrackHeight) / 2  // Adjusted Y position

        sliderTrackView = UIView(frame: CGRect(x: sliderTrackX, y: sliderTrackY, width: sliderTrackWidth, height: sliderTrackHeight))
        sliderTrackView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        sliderTrackView.layer.cornerRadius = 2
        view.addSubview(sliderTrackView)
        
        sliderIndicatorView?.removeFromSuperview()

        let indicatorHeight: CGFloat = sliderTrackHeight / 10
        let positionPercentage = CGFloat(index) / CGFloat(userPosts.count - 1)
        let offsetY = (sliderTrackHeight - indicatorHeight) * positionPercentage

        sliderIndicatorView = UIView(frame: CGRect(x: sliderTrackX, y: sliderTrackY + offsetY, width: sliderTrackWidth, height: indicatorHeight))
        sliderIndicatorView.backgroundColor = UIColor.green
        sliderIndicatorView.layer.cornerRadius = 2
        view.addSubview(sliderIndicatorView)

        // Setup the overlayCenterImageView
        let imageViewWidth = view.bounds.width * 0.9
        let imageViewHeight = imageViewWidth * 0.6
        let imageViewX = (view.bounds.width - imageViewWidth) / 2
        let imageViewY = (view.bounds.height - imageViewHeight) / 2

        overlayCenterImageView = UIImageView(image: tappedImage.image)
        overlayCenterImageView.frame = CGRect(x: imageViewX, y: imageViewY, width: imageViewWidth, height: imageViewHeight)
        overlayCenterImageView.contentMode = .scaleAspectFill
        overlayCenterImageView.clipsToBounds = true
        overlayCenterImageView.layer.cornerRadius = 15
        overlayCenterImageView.layer.borderWidth = 2.0
        overlayCenterImageView.layer.borderColor = UIColor.white.cgColor
        view.addSubview(overlayCenterImageView)
        
        // Setup the Delete Button
        deleteButton = UIButton(frame: CGRect(x: view.bounds.width - 70, y: 70, width: 50, height: 50))
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium, scale: .medium)
        let largeTrashIcon = UIImage(systemName: "trash.circle.fill", withConfiguration: largeConfig)
        deleteButton.setImage(largeTrashIcon, for: .normal)
        deleteButton.tintColor = .red
        deleteButton.layer.cornerRadius = deleteButton.frame.width / 2
        deleteButton.contentMode = .center
        deleteButton.addTarget(self, action: #selector(handleDeleteTapped), for: .touchUpInside)
        view.addSubview(deleteButton)
        

        // Adding Haptic Touch "Pop" Effect
        overlayCenterImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.6, options: [], animations: {
            self.overlayCenterImageView.transform = .identity
        }, completion: nil)

        // If there's a previous image, setup overlayTopImageView
        if index > 0 {
            let previousImage = userPosts[index - 1]
            let topImageY = (imageViewY - 20) - (imageViewHeight * 0.8)
            overlayTopImageView = UIImageView(image: previousImage.image)
            let topFrame = CGRect(x: imageViewX + (imageViewWidth * 0.1),
                                  y: topImageY,
                                  width: imageViewWidth * 0.8,
                                  height: imageViewHeight * 0.8)
            overlayTopImageView.frame = topFrame
            overlayTopImageView.contentMode = .scaleAspectFill
            overlayTopImageView.clipsToBounds = true
            overlayTopImageView.layer.cornerRadius = 12
            overlayTopImageView.alpha = 0.6
            view.addSubview(overlayTopImageView)
        }

        // If there's a next image, setup overlayBottomImageView
        if index < userPosts.count - 1 {
            let nextImage = userPosts[index + 1]
            let bottomImageY = imageViewY + imageViewHeight + 20
            overlayBottomImageView = UIImageView(image: nextImage.image)
            let bottomFrame = CGRect(x: imageViewX + (imageViewWidth * 0.1),
                                     y: bottomImageY,
                                     width: imageViewWidth * 0.8,
                                     height: imageViewHeight * 0.8)
            overlayBottomImageView.frame = bottomFrame
            overlayBottomImageView.contentMode = .scaleAspectFill
            overlayBottomImageView.clipsToBounds = true
            overlayBottomImageView.layer.cornerRadius = 12
            overlayBottomImageView.alpha = 0.6
            view.addSubview(overlayBottomImageView)
        }

        swipeUpGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleOverlaySwipeUp))
        swipeUpGesture!.direction = .up
        swipeUpGesture!.cancelsTouchesInView = true
        view.addGestureRecognizer(swipeUpGesture!)

        swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleOverlaySwipeDown))
        swipeDownGesture!.direction = .down
        swipeDownGesture!.cancelsTouchesInView = true
        view.addGestureRecognizer(swipeDownGesture!)
    }
    

    @objc func closeOverlay() {
        overlayCenterImageView.removeFromSuperview()
        overlayTopImageView?.removeFromSuperview()
        overlayBottomImageView?.removeFromSuperview()
        sliderTrackView.removeFromSuperview()
        sliderIndicatorView.removeFromSuperview()
        backButton.removeFromSuperview()
        deleteButton.removeFromSuperview()
        

        backgroundView?.removeFromSuperview()
        visualEffectView?.removeFromSuperview()
        
        overlayTopImageView = nil
        overlayBottomImageView = nil

        if let swipeUp = swipeUpGesture {
            view.removeGestureRecognizer(swipeUp)
        }
        if let swipeDown = swipeDownGesture {
            view.removeGestureRecognizer(swipeDown)
        }
    }

}


extension ProfileViewController: TOCropViewControllerDelegate {
    func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
        if isUpdatingProfileImage {
            uploadProfileImage(pickedImage: image)
        } else {
            postImageToFirebase(image: image)
        }
        cropViewController.dismiss(animated: true, completion: nil)
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true, completion: nil)
    }
}


extension ProfileViewController {
    private func uploadProfileImage(pickedImage: UIImage) {
        profilePicImage.image = pickedImage
        profilePicImage.backgroundColor = .clear
        
        guard let imageData = pickedImage.jpegData(compressionQuality: 0.8),
              let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("profileImages/\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error)")
                return
            }
            
            imageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    print("An error occurred while getting the download URL: \(error?.localizedDescription ?? "")")
                    return
                }
                
                let db = Firestore.firestore()
                let usersRef = db.collection("users")
                
                usersRef.whereField("uid", isEqualTo: userId).getDocuments { (querySnapshot, err) in
                    if let err = err {
                        print("Error finding user's document: \(err)")
                        return
                    }
                    
                    guard let document = querySnapshot?.documents.first else {
                        print("No matching document found for user's UID")
                        return
                    }
                    
                    document.reference.updateData(["profilePictureURL": downloadURL.absoluteString]) { err in
                        if let err = err {
                            print("Error updating profile picture URL: \(err)")
                        } else {
                            print("Successfully updated profile picture URL in Firestore.")
                        }
                    }
                }
            }
        }
    }
}



extension ProfileViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PopAnimator()
    }
}
