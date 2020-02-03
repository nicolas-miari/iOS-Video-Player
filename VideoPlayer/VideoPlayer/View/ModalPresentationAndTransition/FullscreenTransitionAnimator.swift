//
//  FullscreenTransitionAnimator.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit

class FullscreenTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private(set) internal var phase: AnimatedTransitionPhase

    public var duration: TimeInterval {
        switch phase {
        case .presenting:
            return 0.25
        case .dismissing:
            return 0.25
        }
    }

    init(phase: AnimatedTransitionPhase) {
        self.phase = phase
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        switch phase {
        case .presenting:
            animatePresentation(using: transitionContext)

        case .dismissing:
            animateDismissal(using: transitionContext)
        }
    }

    public func animationEnded(_ transitionCompleted: Bool) {
    }

    // MARK: - Support

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        /*
        Most comments taken from steps in the documentation:
        https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html#//apple_ref/doc/uid/TP40007457-CH16-SW1)
        */

        /*
         1. Use the viewControllerForKey: and viewForKey: methods to retrieve
            the view controllers and views involved in the transition:
         */
        guard let toViewController = transitionContext.viewController(forKey: .to) as? PlayerViewController else {
            return
        }
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }

        /*
         2. Set the starting position of the “to” (presented) view. Set any
         other properties to their starting values as well.
         */
        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
        toView.frame = toViewController.sourceFrame

        /*
         3. Get the end position of the “to” view from the
         finalFrameForViewController: method of the context transitioning
         context.
         */

        /*
         4. Add the “to” view as a subview of the container view.
         */
        transitionContext.containerView.addSubview(toView)

        /*
         5. Create the animations.
         */
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            /*
             In your animation block, animate the “to” view to its final
             location in the container view. Set any other properties to their
             final values as well.
             */
            toView.frame = toViewFinalFrame

        }, completion: {(completed) in
            /*
             In the completion block, call the completeTransition: method, and
             perform any other cleanup.
             */
            transitionContext.completeTransition(completed)
        })
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        /*
        Most comments taken from steps in the documentation:
        https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/CustomizingtheTransitionAnimations.html#//apple_ref/doc/uid/TP40007457-CH16-SW1)
        */

        /*
         1. Use the viewControllerForKey: and viewForKey: methods to retrieve
            the view controllers and views involved in the transition.
         */
        guard let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? PlayerViewController else {
            return
        }
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        /*
         This prevents momentary layout breaking in the presenting view
         controller if the device orientation changed while presenting:
         (thanks to: https://stackoverflow.com/a/35007286/433373)
         */
        toView.frame = fromView.frame

        /*
         2. Compute the end position of the “from” view. This view belongs to
            the presented view controller that is now being dismissed.
         */
        let dismissFrame = fromViewController.sourceFrame

        /*
         3. Add the “to” view as a subview of the container view. During a
            presentation, the view belonging to the presenting view controller
            is removed when the transition completes. As a result, you must
            add that view back to the container during a dismissal operation.

            Note: the "to" view is nil if the presenting view wasn't removed as
            a result of the presentation (as in the non-fullscreen modal
            presentation we are attempting), so make optional:
        */
        if let toView = transitionContext.view(forKey: .to) {
            transitionContext.containerView.insertSubview(toView, at: 0)
        }

        /*
         4. Create the animations.
         */
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
            /*
             In your animation block, animate the “from” view to its final
             location in the container view. Set any other properties to their
             final values as well.
             */
            fromView.frame = dismissFrame

        }, completion: {(completed) in
            /*
             In the completion block, remove the “from” view from your view
             hierarchy and call the completeTransition: method. Perform any
             other cleanup as needed.
             */
            fromView.removeFromSuperview()
            transitionContext.completeTransition(completed)
        })
    }
}

// MARK: - Supporting Types

enum AnimatedTransitionPhase {
    case presenting
    case dismissing
}
