// EnlargedPhotoViewController.swift Working so far

import UIKit

class EnlargedPhotoViewController: UIViewController {
    
    var selectedImage: UIImage?
    var profileImage: UIImage?
    var userName: String?
    var images: [UIImage] = []
    var selectedIndex: Int = 0
    
    // New for stack subviews
    var centerImageView: UIImageView!
    var topImageView: UIImageView!
    var bottomImageView: UIImageView!
    var previousImage: UIImage?
    var nextImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Assuming the images array and selectedIndex are already populated
        let currentImage = images[selectedIndex]

        // Setup the centerImageView
        centerImageView = UIImageView(image: currentImage)
        centerImageView.frame = self.view.bounds
        centerImageView.contentMode = .scaleAspectFill
        centerImageView.clipsToBounds = true
        centerImageView.layer.cornerRadius = 15 // for rounded edges
        self.view.addSubview(centerImageView)

        // Setup the topImageView (for the previous image)
        if selectedIndex > 0 {
            topImageView = UIImageView(image: images[selectedIndex - 1])
            let topFrame = CGRect(x: centerImageView.frame.origin.x + (centerImageView.frame.width * 0.1),
                                  y: centerImageView.frame.origin.y - centerImageView.frame.height * 0.8,
                                  width: centerImageView.frame.width * 0.8,
                                  height: centerImageView.frame.height * 0.8)
            topImageView.frame = topFrame
            topImageView.contentMode = .scaleAspectFill
            topImageView.clipsToBounds = true
            topImageView.layer.cornerRadius = 12 // Slightly smaller rounded edges
            topImageView.alpha = 0.6 // Dimmed effect
            self.view.addSubview(topImageView)
        }

        // Setup the bottomImageView (for the next image)
        if selectedIndex < images.count - 1 {
            bottomImageView = UIImageView(image: images[selectedIndex + 1])
            let bottomFrame = CGRect(x: centerImageView.frame.origin.x + (centerImageView.frame.width * 0.1),
                                     y: centerImageView.frame.origin.y + centerImageView.frame.height,
                                     width: centerImageView.frame.width * 0.8,
                                     height: centerImageView.frame.height * 0.8)
            bottomImageView.frame = bottomFrame
            bottomImageView.contentMode = .scaleAspectFill
            bottomImageView.clipsToBounds = true
            bottomImageView.layer.cornerRadius = 12 // Slightly smaller rounded edges
            bottomImageView.alpha = 0.6 // Dimmed effect
            self.view.addSubview(bottomImageView)
        }

        // Add swipe gestures (to be implemented)
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
    }

    @objc func handleSwipeUp() {
        // Ensure there's a next image
        if selectedIndex < images.count - 1 {
            // Animate the transition
            UIView.animate(withDuration: 0.3, animations: {
                // Move current image up
                self.centerImageView.frame.origin.y -= self.view.bounds.height
                // Move the next image to center
                self.bottomImageView.frame = self.centerImageView.frame
            }) { _ in
                // Update the selectedIndex and refresh the image views
                self.selectedIndex += 1
                self.refreshImageViews()
            }
        }
    }

    @objc func handleSwipeDown() {
        // Ensure there's a previous image
        if selectedIndex > 0 {
            // Animate the transition
            UIView.animate(withDuration: 0.3, animations: {
                // Move current image down
                self.centerImageView.frame.origin.y += self.view.bounds.height
                // Move the previous image to center
                self.topImageView.frame = self.centerImageView.frame
            }) { _ in
                // Update the selectedIndex and refresh the image views
                self.selectedIndex -= 1
                self.refreshImageViews()
            }
        }
    }

    func refreshImageViews() {
        // Update the images for the views based on the new selectedIndex
        
        centerImageView.image = images[selectedIndex]
        
        // Update topImageView if there's a previous image, or hide it if there isn't
        if selectedIndex > 0 {
            topImageView.isHidden = false
            topImageView.image = images[selectedIndex - 1]
        } else {
            topImageView.isHidden = true
        }
        
        // Update bottomImageView if there's a next image, or hide it if there isn't
        if selectedIndex < images.count - 1 {
            bottomImageView.isHidden = false
            bottomImageView.image = images[selectedIndex + 1]
        } else {
            bottomImageView.isHidden = true
        }
    }
}


