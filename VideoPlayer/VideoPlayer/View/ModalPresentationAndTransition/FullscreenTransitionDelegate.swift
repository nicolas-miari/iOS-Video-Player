//
//  FullscreenTransitionDelegate.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit

class FullscreenTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {

    static let `default` = FullscreenTransitionDelegate()

    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil // (Interactive presentation is NOT supported)
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil // (Interactive dismissal is NOT supported)
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FullscreenTransitionAnimator(phase: .presenting)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return FullscreenTransitionAnimator(phase: .dismissing)
    }

    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        /*
         We're not doing custom presentation (unlike an alert or sheet, no
         dimming or other auxiliary views are needed). Return the stock
         `UIPresentationController` (or alternatively, do not implement this
         method at all)
         */
        return UIPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
