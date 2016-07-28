//
//  FAMFullscreenViewController.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/26.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit

@objc public enum FAMFullscreenContentType: Int {
    /// display image
    case Image
    /// display video
    case Video
    /// unknown
    case None
}

public enum FAMFullscreenImageRequestResult {
    /// request image success
    case Success(UIImage)
    /// request image failure
    case Failure
}

public typealias FAMFullscreenImageRequest = (result: FAMFullscreenImageRequestResult) -> Void

/// dataSource for FAMFullscreenViewController
public protocol FAMFullscreenViewControllerDataSource: class {
    /**
     return number of sections

     - parameter viewController: FAMFullscreenMainViewController

     - returns: numberOfsections Int
     */
    func numberOfSections(inFullscreenViewController viewController: FAMFullscreenMainViewController) -> Int

    /**
     return number of items in section

     - parameter viewController: FAMFullscreenMainViewController
     - parameter section:        Int

     - returns: numberOfItems Int
     */
    func fullscreenViewController(viewController: FAMFullscreenMainViewController, numberOfItemsInSection section: Int) -> Int

    /**
     return content type
     display play button when content type is Video

     - parameter viewController: FAMFullscreenMainViewController
     - parameter indexPath:      NSIndexPath

     - returns: FAMFullscreenContentType
     */
    func fullscreenViewController(viewController: FAMFullscreenMainViewController, contentTypeAtIndexPath indexPath: NSIndexPath) -> FAMFullscreenContentType

    /**
     request image at index path

     - parameter viewController: FAMFullscreenMainViewController
     - parameter indexPath:      NSIndexPath
     - parameter request:        FAMFullscreenImageRequest

     - returns: Void
     */
    func fullscreenViewController(viewController: FAMFullscreenMainViewController, requestImageAtIndexPath indexPath: NSIndexPath, request: FAMFullscreenImageRequest) -> Void
}

/// FAMFullscreenViewControllerDelegate
@objc public protocol FAMFullscreenViewControllerDelegate: class {
    /**
     rect for indexPath.
     needed by display transition.

     - parameter viewController: FAMFullscreenViewController
     - parameter indexPath:      NSIndexPath

     - returns: CGRect
     */
    func fullscreenViewController(viewController: FAMFullscreenViewController, rectForIndexPath indexPath: NSIndexPath) -> CGRect

    /**
     absolute rect for indexPath

     - parameter viewController: FAMFullscreenViewController
     - parameter indexPath:      NSIndexPath

     - returns: CGRect
     */
    func fullscreenViewController(viewController: FAMFullscreenViewController, absoluteRectForIndexPath indexPath: NSIndexPath) -> CGRect

    /**
     get thumbnail image for indexPath.

     - parameter viewController: FAMFullscreenViewController
     - parameter indexPath:      NSIndexPath

     - returns: UIImage?
     */
    func fullscreenViewController(viewController: FAMFullscreenViewController, thumbnailImageForIndexPath indexPath: NSIndexPath) -> UIImage?
    /**
     adjust content offset with rect

     - parameter viewController: FAMFullscreenViewController
     - parameter rect:           CGRect

     - returns: CGRect
     */
    func fullscreenViewController(viewController: FAMFullscreenViewController, adjustContentOffsetWithRect rect: CGRect, absoluteRect: CGRect, withIndexPath indexPath: NSIndexPath) -> CGRect

    /**
     called if changed displaying indexPath

     - parameter viewController: FAMFullscreenMainViewController
     - parameter indexPath:      NSIndexPath

     - returns: Void
     */
    optional func fullscreenViewController(viewController: FAMFullscreenMainViewController, didShowIndexPath indexPath: NSIndexPath) -> Void
}

///FAMFullscreenViewController
public class FAMFullscreenViewController: UINavigationController {
    private enum Constants {
        static let closeBorder: CGFloat = UIScreen.mainScreen().bounds.size.height / 1.5
        static let closeRate: CGFloat = 0.35
    }

    /// mainViewController: FAMFullscreenMainViewController
    private (set) public var mainViewController: FAMFullscreenMainViewController!
    /// selectedIndexPath: NSIndexPath
    private var selectedIndexPath: NSIndexPath! {
        set(newValue) {
            self.mainViewController.selectedIndexPath = newValue
        }
        get {
            return self.mainViewController.selectedIndexPath
        }
    }

    public required init(selectedIndexPath: NSIndexPath) {
        self.mainViewController = FAMFullscreenMainViewController(selectedIndexPath: selectedIndexPath)
        super.init(nibName: nil, bundle: nil)
        self.automaticallyAdjustsScrollViewInsets = false
        self.viewControllers = [self.mainViewController]
        self.modalPresentationStyle = UIModalPresentationStyle.Custom
        self.transitioningDelegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public weak var fullscreenDataSource: FAMFullscreenViewControllerDataSource? {
        set(newValue) {
            self.mainViewController.dataSource = newValue
        }
        get {
            return self.mainViewController.dataSource
        }
    }
    public weak var fullscreenDelegate: FAMFullscreenViewControllerDelegate? {
        set(newValue) {
            self.mainViewController.delegate = newValue
        }
        get {
            return self.mainViewController.delegate
        }
    }

    /// is parallax effect visible true
    public var showParallax: Bool = false {
        didSet {
            self.mainViewController.showParallax = self.showParallax
        }
    }

    //MARK: interactive transitions
    private var isInteractive: Bool = false
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        UIPanGestureRecognizer(target: self, action: #selector(self.panGestureDidReceived))
    }()

    private var startPoint: CGPoint = CGPoint.zero
    func panGestureDidReceived(panGesture: UIPanGestureRecognizer) {
        let translation: CGPoint = panGesture.translationInView(panGesture.view)
        let height: CGFloat = (panGesture.view?.frame.size.height ?? UIScreen.mainScreen().bounds.size.height) / 1.5
        let percent: CGFloat = fabs(translation.y / height)

        switch panGesture.state {
        case UIGestureRecognizerState.Began:
            self.isInteractive = true
            self.startPoint = panGesture.locationInView(panGesture.view)
            self.dismissViewControllerAnimated(true, completion: nil)
        case UIGestureRecognizerState.Changed:
            self.transition.updateInteractiveTransition(percent)
            self.transition.imageView.transform = CGAffineTransformMakeTranslation(translation.x, translation.y)
        case UIGestureRecognizerState.Cancelled:
            self.transition.cancelInteractiveTransition()
        case UIGestureRecognizerState.Ended:
            if percent >= Constants.closeRate {
                self.transition.finishInteractiveTransition()
            } else {
                self.transition.cancelInteractiveTransition()
            }
        default:
            self.transition.cancelInteractiveTransition()
            break
        }
    }

    //MARK: transition
    private lazy var transition: FAMFullscreenTransition = {
        let transition: FAMFullscreenTransition = FAMFullscreenTransition(direction: FAMFullscreenTransitionDirection.Open)
        transition.delegate = self
        return transition
    }()
}

//MARK: lifecycle
extension FAMFullscreenViewController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.mainViewController.view.addGestureRecognizer(self.panGestureRecognizer)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension FAMFullscreenViewController: UIViewControllerTransitioningDelegate {
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transition.direction = FAMFullscreenTransitionDirection.Open
        return self.transition
    }

    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.transition.direction = FAMFullscreenTransitionDirection.Close
        return self.transition
    }

    public func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }

    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive {
            self.transition.direction = FAMFullscreenTransitionDirection.Close
            return self.transition.interactiveTransition
        }
        return nil
    }
}

// MARK: - FAMFullscreenTransitionDelegate
extension FAMFullscreenViewController: FAMFullscreenTransitionDelegate {
    public func transitionFromRect(transiion: FAMFullscreenTransition) -> CGRect {
        return self.fullscreenDelegate?.fullscreenViewController(self, rectForIndexPath: self.selectedIndexPath) ?? CGRect.zero
    }

    public func transitionAbsoluteFromRect(transition: FAMFullscreenTransition) -> CGRect {
        return self.fullscreenDelegate?.fullscreenViewController(self, absoluteRectForIndexPath: self.selectedIndexPath) ?? CGRect.zero
    }

    public func adjustContentOffset(rect: CGRect, absoluteRect: CGRect) -> CGRect {
        return self.fullscreenDelegate?.fullscreenViewController(self, adjustContentOffsetWithRect: rect, absoluteRect: absoluteRect, withIndexPath: self.selectedIndexPath) ?? CGRect.zero
    }

    public func transitionImage(transition: FAMFullscreenTransition) -> UIImage? {
        guard let cell: FAMFullscreenCell = self.mainViewController.collectionView.cellForItemAtIndexPath(self.selectedIndexPath) as? FAMFullscreenCell else {
            return self.fullscreenDelegate?.fullscreenViewController(self, thumbnailImageForIndexPath: self.selectedIndexPath)
        }

        return cell.image
    }

    public func transitionToRect(transition: FAMFullscreenTransition) -> CGRect {
        return UIApplication.sharedApplication().keyWindow?.bounds ?? UIScreen.mainScreen().bounds
    }
}

/// FAMFullscreenMainViewController
public class FAMFullscreenMainViewController: UIViewController {
    private enum Constants {
        static let parallaxWidth: CGFloat = 40.0
    }

    /// collectionViewLayout
    private lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 0.0
        layout.itemSize = self.view.bounds.size
        layout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        return layout
    }()

    private var initializedCount: Int = 0
    /// collectionView
    private (set) public lazy var collectionView: UICollectionView = {
        let result: UICollectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.collectionViewLayout)
        result.registerClass(FAMFullscreenCell.self, forCellWithReuseIdentifier: FAMFullscreenCell.cellIdentifier)
        result.translatesAutoresizingMaskIntoConstraints = false
        result.pagingEnabled = true
        result.dataSource = self
        result.delegate = self
        result.showsVerticalScrollIndicator = false
        result.showsHorizontalScrollIndicator = false
        return result
    }()

    public var selectedIndexPath: NSIndexPath
    public init(selectedIndexPath: NSIndexPath) {
        self.selectedIndexPath = selectedIndexPath
        super.init(nibName: nil, bundle: nil)
        self.automaticallyAdjustsScrollViewInsets = false
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public weak var dataSource: FAMFullscreenViewControllerDataSource?
    public weak var delegate: FAMFullscreenViewControllerDelegate?

    /// parallax
    public var showParallax: Bool = false {
        didSet {
            if !self.isViewLoaded() {
                return
            }

            if self.showParallax {
                if !self.collectionView.subviews.contains(self.parallaxView) {
                    self.collectionView.addSubview(self.parallaxView)
                }
            } else {
                if self.collectionView.subviews.contains(self.parallaxView) {
                    self.parallaxView.removeFromSuperview()
                }
            }
        }
    }

    private lazy var parallaxView: UIView = {
        let view: UIView = UIView(frame: CGRect(x: -Constants.parallaxWidth, y: 0.0, width: Constants.parallaxWidth, height: self.collectionView.frame.size.height))
        view.backgroundColor = self.collectionView.backgroundColor
        return view
    }()
}

// MARK: - lifecycle
extension FAMFullscreenMainViewController {
    public override func loadView() {
        super.loadView()

        self.view.userInteractionEnabled = true
        self.view.addSubview(self.collectionView)
        self.view.addConstraints([
            NSLayoutConstraint(item: self.collectionView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.collectionView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.collectionView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.collectionView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0),
        ])

        let closeButton: UIBarButtonItem = UIBarButtonItem(title: "close", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(self.close))
        self.navigationItem.leftBarButtonItem = closeButton
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        if self.showParallax {
            self.showParallax = true
        } else {
            self.showParallax = false
        }
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        if self.showParallax {
            self.parallaxView.frame = CGRect(x: -Constants.parallaxWidth, y: 0.0, width: Constants.parallaxWidth, height: self.view.bounds.size.height)
        }
        self.scrollToIndexPath(self.selectedIndexPath)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    private func scrollToIndexPath(indexPath: NSIndexPath) {
        self.collectionView.performBatchUpdates({ [unowned self] in
            self.collectionViewLayout.itemSize = self.view.bounds.size
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: UICollectionViewScrollPosition.CenteredHorizontally, animated: false)
        }, completion: nil)
    }

    @objc private func close() {
        if let navigationController: FAMFullscreenViewController = self.navigationController as? FAMFullscreenViewController {
            navigationController.isInteractive = false
        }
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - UIScrollViewDelegate
extension FAMFullscreenMainViewController: UIScrollViewDelegate {
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if self.showParallax {
            // parallaxの計算
            let indexPath: NSIndexPath
            let indexPaths: [NSIndexPath] = self.collectionView.indexPathsForVisibleItems()
            if 2 == indexPaths.count {
                indexPath = indexPaths[0].compare(indexPaths[1]) == .OrderedAscending ? indexPaths[1] : indexPaths[0]
            } else if 1 == indexPaths.count {
                indexPath = indexPaths[0]
            } else {
                return
            }

            let width: CGFloat = self.collectionView.frame.width
            guard let cell: UICollectionViewCell = self.collectionView.cellForItemAtIndexPath(indexPath) else {
                return
            }

            let cellRectInWindow: CGRect = self.collectionView.convertRect(cell.frame, toView: nil)

            // progress は基本的には 0.0 ~ 1.0 の値をとるが、最後の一枚が左に移動している間のみ以下の計算式では値がマイナスになる。
            let progress: CGFloat = 1.0 - (width - cellRectInWindow.origin.x) / width
            var frame: CGRect = CGRect.zero

            let start: CGFloat = progress >= 0.0 ? cell.frame.minX : cell.frame.maxX
            let factor: CGFloat = progress >= 0.0 ? (1.0 - progress) : abs(progress)
            frame.origin.x = start - Constants.parallaxWidth * factor
            frame.size = parallaxView.frame.size

            self.parallaxView.frame = frame
        }
    }

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if !scrollView.decelerating && !scrollView.dragging && !scrollView.tracking {
            self.scrollViewDidEndScrolling(scrollView)
        }
    }

    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !scrollView.decelerating && !scrollView.dragging && !scrollView.tracking {
            self.scrollViewDidEndScrolling(scrollView)
        }
    }

    public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        if !scrollView.decelerating && !scrollView.dragging && !scrollView.tracking {
            self.scrollViewDidEndScrolling(scrollView)
        }
    }

    private func scrollViewDidEndScrolling(scrollView: UIScrollView) {
        guard scrollView == self.collectionView else {
            return
        }

        guard let indexPath: NSIndexPath = self.collectionView.indexPathForItemAtPoint(scrollView.contentOffset) else {
            return
        }

        self.selectedIndexPath = indexPath
        self.delegate?.fullscreenViewController?(self, didShowIndexPath: indexPath)
    }
}

// MARK: - UICollectionViewDataSource
extension FAMFullscreenMainViewController: UICollectionViewDataSource {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.dataSource?.numberOfSections(inFullscreenViewController: self) ?? 0
    }

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.dataSource?.fullscreenViewController(self, numberOfItemsInSection: section) ?? 0
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell: FAMFullscreenCell = collectionView.dequeueReusableCellWithReuseIdentifier(FAMFullscreenCell.cellIdentifier, forIndexPath: indexPath) as? FAMFullscreenCell else {
            fatalError("cell create failed.")
        }

        if let _ = cell.viewController.parentViewController {
            cell.viewController.willMoveToParentViewController(nil)
            cell.viewController.removeFromParentViewController()
            cell.viewController.didMoveToParentViewController(nil)
        }

        self.dataSource?.fullscreenViewController(self, requestImageAtIndexPath: indexPath, request: { (result) in
            switch result {
            case FAMFullscreenImageRequestResult.Success(let image):
                cell.image = image
            case FAMFullscreenImageRequestResult.Failure:
                cell.image = nil
            }
        })

        cell.viewController.indexPath = indexPath
        cell.viewController.willMoveToParentViewController(self)
        self.addChildViewController(cell.viewController)
        cell.viewController.didMoveToParentViewController(self)

        return cell
    }
}

extension FAMFullscreenMainViewController: UICollectionViewDelegate {

}
