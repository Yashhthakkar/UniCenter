//
//  TabHaptics.swift
//  UniConnect
//
//  Created by Yash Thakkar on 8/27/23.
//

import UIKit

class TabHaptics: UITabBarController, UITabBarControllerDelegate {
    
    var previousTabIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let currentTabIndex = tabBarController.selectedIndex
        

        guard currentTabIndex != previousTabIndex else {
            return
        }
        
        previousTabIndex = currentTabIndex
        

        let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
    }

    

}
