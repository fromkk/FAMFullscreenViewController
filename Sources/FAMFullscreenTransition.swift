//
//  FAMFullscreenTransition.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/27.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit

/**
 transition direction

 - Open:  present view controller
 - Close: dismiss view controller
 */
@objc public enum FAMFullscreenTransitionDirection: Int {
    case Open
    case Close

    public func duration() -> NSTimeInterval {
        return 0.33
    }
}

/// transition delegate
public protocol FAMFullscreenTransitionDelegate: class {
    func transitionFromRect(transiion: FAMFullscreenTransition) -> CGRect
    func transitionAbsoluteFromRect(transition: FAMFullscreenTransition) -> CGRect
    func transitionImage(transition: FAMFullscreenTransition) -> UIImage?
    func adjustContentOffset(rect: CGRect, absoluteRect: CGRect) -> CGRect
}

/// FAMFullscreenTransition
public class FAMFullscreenTransition: NSObject {
    public var direction: FAMFullscreenTransitionDirection
    public init(direction: FAMFullscreenTransitionDirection) {
        self.direction = direction
        super.init()
    }

    /// FAMFullscreenTransitionDelegate
    public var delegate: FAMFullscreenTransitionDelegate!
    lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        return imageView
    }()

    /// open frame
    private var toFrame: CGRect {
        let screenFrame: CGRect = UIApplication.sharedApplication().keyWindow?.bounds ?? UIScreen.mainScreen().bounds
        let imageSize: CGSize = self.imageView._famFullScreenSizeForAspectFit(screenFrame.size)
        let result: CGRect = CGRect(origin: CGPoint(x: (screenFrame.size.width - imageSize.width) / 2.0, y: (screenFrame.size.height - imageSize.height) / 2.0), size: imageSize)
        return result
    }
    /// close frame
    private var fromFrame: CGRect = CGRect.zero

    /// interactive gesture start position
    private var startPosition: CGPoint = CGPoint.zero

    /// interactive transition
    public lazy var interactiveTransition: UIPercentDrivenInteractiveTransition = {
        UIPercentDrivenInteractiveTransition()
    }()

    /// when interactive transition finished called
    private var finishClosure: () -> Void = {}

    /// when interactive transition cancelled called
    private var cancelClosure: () -> Void = {}
}

extension FAMFullscreenTransition: UIViewControllerAnimatedTransitioning {
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return self.direction.duration()
    }

    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController: UIViewController = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey),
            toViewController: UIViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
        containerView: UIView = transitionContext.containerView() else {
            return
        }

        let toView: UIView = toViewController.view
        let fromView: UIView = fromViewController.view

        if self.direction == FAMFullscreenTransitionDirection.Open {
            containerView.insertSubview(toView, aboveSubview: fromView)
            toView.alpha = 0.0
            containerView.addSubview(self.imageView)

            self.imageView.image = self.delegate.transitionImage(self)
            self.imageView.frame = self.delegate.transitionFromRect(self)

            UIView.animateWithDuration(self.direction.duration(), animations: { [unowned self] in
                self.imageView.frame = self.toFrame
            }, completion: { [unowned self] (finished: Bool) in
                toView.alpha = 1.0
                self.imageView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        } else {
            containerView.addSubview(self.imageView)

            self.imageView.image = self.delegate.transitionImage(self)
            self.imageView.frame = self.toFrame

            fromView.alpha = 0.0

            self.fromFrame = self.delegate.adjustContentOffset(self.delegate.transitionFromRect(self), absoluteRect: self.delegate.transitionAbsoluteFromRect(self))
            if !transitionContext.isInteractive() {
                UIView.animateWithDuration(self.direction.duration(), animations: { [unowned self] in
                    self.imageView.frame = self.fromFrame
                    }, completion: { [unowned self] (finished: Bool) in
                        fromView.alpha = 1.0
                        self.imageView.removeFromSuperview()
                        transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
                    })
            } else {
                self.finishClosure = { [weak self] in
                    fromView.alpha = 1.0
                    self?.imageView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }

                self.cancelClosure = { [weak self] in
                    fromView.alpha = 1.0
                    self?.imageView.removeFromSuperview()
                    transitionContext.completeTransition(false)
                }
            }
        }
    }
}

protocol FAMFullscreenInteractive {
    func updateInteractiveTransition(percentComplete: CGFloat) -> Void
    func finishInteractiveTransition() -> Void
    func cancelInteractiveTransition() -> Void
}

extension FAMFullscreenTransition: FAMFullscreenInteractive {
    func updateInteractiveTransition(percentComplete: CGFloat) {
        self.interactiveTransition.updateInteractiveTransition(percentComplete)
    }

    func finishInteractiveTransition() {
        self.interactiveTransition.finishInteractiveTransition()

        UIView.animateWithDuration(self.direction.duration(), animations: { [weak self] in
            self?.imageView.frame = self?.fromFrame ?? CGRect.zero
        }) { [weak self] (finished: Bool) in
            self?.finishClosure()
        }
    }

    func cancelInteractiveTransition() {
        self.interactiveTransition.cancelInteractiveTransition()

        UIView.animateWithDuration(self.direction.duration(), animations: { [weak self] in
            self?.imageView.frame = self?.toFrame ?? CGRect.zero
        }) { [weak self] (finished: Bool) in
            self?.cancelClosure()
        }
    }
}
