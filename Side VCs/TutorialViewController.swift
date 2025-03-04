//
//  TutorialViewController.swift
//  UniConnect
//
//  Created by Yash Thakkar on 11/22/23.
//

import UIKit

class TutorialViewController: UIViewController, UIScrollViewDelegate {

    var scrollView: UIScrollView!
    var pageControl: UIPageControl!
    let pageContents = [
        ("Home", "Discover recommendations in user cards. Heart those you find attractive."),
        ("Search", "Search for profiles within your college."),
        ("Inbox", "View all your notifications."),
        ("Profile", "Edit your profile and post images.")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollView()
        setupPageControl()
        loadTutorialPages()
        view.backgroundColor = .white
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        view.addSubview(scrollView)
    }
    
    private func setupPageControl() {
        pageControl = UIPageControl(frame: CGRect(x: 0, y: view.frame.height - 50, width: view.frame.width, height: 50))
        pageControl.numberOfPages = pageContents.count
        pageControl.currentPage = 0
        pageControl.addTarget(self, action: #selector(pageControlChanged(_:)), for: .valueChanged)
        view.addSubview(pageControl)
    }
    
    private func loadTutorialPages() {
        for (index, content) in pageContents.enumerated() {
            let pageFrame = CGRect(x: CGFloat(index) * view.frame.width, y: 0, width: view.frame.width, height: view.frame.height)
            let pageView = createPageView(frame: pageFrame, title: content.0, description: content.1)
            scrollView.addSubview(pageView)
        }
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(pageContents.count), height: view.frame.height)
    }
    
    private func createPageView(frame: CGRect, title: String, description: String) -> UIView {
        let pageView = UIView(frame: frame)
        
        let titleLabel = UILabel(frame: CGRect(x: 20, y: 100, width: frame.width - 40, height: 30))
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.text = title
        pageView.addSubview(titleLabel)
        
        let descriptionLabel = UILabel(frame: CGRect(x: 20, y: titleLabel.frame.maxY + 10, width: frame.width - 40, height: 100))
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.text = description
        pageView.addSubview(descriptionLabel)
        
        // TODO: Find UI images to add
        
        return pageView
    }
    
    @objc func pageControlChanged(_ sender: UIPageControl) {
        let newOffset = CGPoint(x: scrollView.frame.width * CGFloat(sender.currentPage), y: 0)
        scrollView.setContentOffset(newOffset, animated: true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x/view.frame.width)
        pageControl.currentPage = Int(pageIndex)
    }
}

