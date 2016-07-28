//
//  FAMFullscreenTransition.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/27.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit

@objc public enum FAMFullscreenTransitionDirection: Int {
    case Open
    case Close

    public func duration() -> NSTimeInterval {
        switch self {
        case .Open:
            return 0.35
        case .Close:
            return 0.5
        }
    }
}

public protocol FAMFullscreenTransitionDelegate: class {
    func transitionFromRect(transiion: FAMFullscreenTransition) -> CGRect
    func transitionAbsoluteFromRect(transition: FAMFullscreenTransition) -> CGRect
    func transitionImage(transition: FAMFullscreenTransition) -> UIImage?
    func adjustContentOffset(rect: CGRect, absoluteRect: CGRect) -> CGRect
}

public class FAMFullscreenTransition: NSObject {
    public var direction: FAMFullscreenTransitionDirection
    public init(direction: FAMFullscreenTransitionDirection) {
        self.direction = direction
        super.init()
    }

    public var delegate: FAMFullscreenTransitionDelegate!
    private lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        return imageView
    }()

    private var toFrame: CGRect {
        let screenFrame: CGRect = UIApplication.sharedApplication().keyWindow?.bounds ?? UIScreen.mainScreen().bounds
        let imageSize: CGSize = self.imageView._famFullScreenSizeForAspectFit(screenFrame.size)
        let result: CGRect = CGRect(origin: CGPoint(x: (screenFrame.size.width - imageSize.width) / 2.0, y: (screenFrame.size.height - imageSize.height) / 2.0), size: imageSize)
        return result
    }
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
                if finished {
                    self.imageView.removeFromSuperview()
                    toView.alpha = 1.0
                    transitionContext.completeTransition(true)
                }
            })
        } else {
            containerView.addSubview(self.imageView)

            self.imageView.image = self.delegate.transitionImage(self)
            self.imageView.frame = self.toFrame

            fromView.alpha = 0.0

            let fromRect: CGRect = self.delegate.adjustContentOffset(self.delegate.transitionFromRect(self), absoluteRect: self.delegate.transitionAbsoluteFromRect(self))
            UIView.animateWithDuration(self.direction.duration(), animations: { [unowned self] in
                self.imageView.frame = fromRect
            }, completion: { [unowned self] (finished: Bool) in
                if finished {
                    self.imageView.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
            })
        }
    }
}
