//
//  PopAnimator.swift
//  UniConnect
//
//  Created by Yash Thakkar on 8/31/23.
//

import UIKit
import Foundation

class PopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else { return }

        let containerView = transitionContext.containerView
        containerView.addSubview(toViewController.view)

        toViewController.view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            toViewController.view.transform = CGAffineTransform.identity
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
    }
}
