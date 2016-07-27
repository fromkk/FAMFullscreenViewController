//
//  ViewController.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/26.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

enum PhotoLibraryRequestResult: Int {
    case Success
    case Failure
}

typealias PhotoLibraryRequested = (result: PhotoLibraryRequestResult) -> Void

class ViewControllerCell: UICollectionViewCell {
    static let cellIdentifier: String = "viewControllerCell"
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.whiteColor()
        self.contentView.addSubview(self.imageView)
        self.contentView.addConstraints([
            NSLayoutConstraint(item: self.imageView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.imageView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.imageView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.imageView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private (set) lazy var imageView: UIImageView = {
        let imageView: UIImageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        imageView.userInteractionEnabled = true
        return imageView
    }()

    var imageRequestID: PHImageRequestID?
}

class ViewController: UIViewController {
    private enum Constants {
        static let margin: CGFloat = 1.0
        static let rows: Int = 4
    }

    lazy var collectionViewLayout: UICollectionViewFlowLayout = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Constants.margin
        layout.minimumInteritemSpacing = Constants.margin

        let length: CGFloat = (self.view.bounds.size.width - CGFloat(Constants.rows + 1) * Constants.margin) / CGFloat(Constants.rows)
        layout.itemSize = CGSize(width: length, height: length)
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical

        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView: UICollectionView = UICollectionView(frame: self.view.bounds, collectionViewLayout: self.collectionViewLayout)
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.registerClass(ViewControllerCell.self, forCellWithReuseIdentifier: ViewControllerCell.cellIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    var fetchResult: PHFetchResult?
    lazy var imageManager: PHCachingImageManager = {
        let imageManager: PHCachingImageManager = PHCachingImageManager()
        return imageManager
    }()

    override func loadView() {
        super.loadView()

        self.view.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(self.collectionView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.requestPhotoLibrary { [unowned self] (result: PhotoLibraryRequestResult) in
            if result == PhotoLibraryRequestResult.Success {
                guard let collection: PHAssetCollection = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.SmartAlbum, subtype: PHAssetCollectionSubtype.SmartAlbumUserLibrary, options: nil).firstObject as? PHAssetCollection else {
                    return
                }
                self.fetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
                self.collectionView.reloadData()
            }
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    private func requestPhotoLibrary(result: PhotoLibraryRequested) {
        switch PHPhotoLibrary.authorizationStatus() {
        case .Authorized:
            result(result: PhotoLibraryRequestResult.Success)
            return
        case .NotDetermined:
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                switch status {
                case .Authorized:
                    result(result: PhotoLibraryRequestResult.Success)
                    return
                default:
                    result(result: PhotoLibraryRequestResult.Failure)
                    return
                }
            })
        default:
            result(result: PhotoLibraryRequestResult.Failure)
            return
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult?.count ?? 0
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        guard let cell: ViewControllerCell = collectionView.dequeueReusableCellWithReuseIdentifier(ViewControllerCell.cellIdentifier, forIndexPath: indexPath) as? ViewControllerCell else {
            fatalError("viewControllerCell generate failed")
        }
        if let asset: PHAsset = self.fetchResult?.objectAtIndex(indexPath.row) as? PHAsset {
            cell.imageRequestID = self.imageManager.requestImageForAsset(asset, targetSize: cell.frame.size, contentMode: PHImageContentMode.Default, options: nil, resultHandler: { (image: UIImage?, meta: [NSObject : AnyObject]?) in
                guard let imageRequestID: PHImageRequestID = (meta?[PHImageResultRequestIDKey] as? NSNumber)?.intValue else {
                    print("imageRequestID get failed")
                    return
                }

                if let image = image where cell.imageRequestID == imageRequestID {
                    cell.imageView.image = image
                }
            })
        }

        return cell
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell: ViewControllerCell = cell as? ViewControllerCell else {
            return
        }

        if let imageRequestID: PHImageRequestID = cell.imageRequestID {
            self.imageManager.cancelImageRequest(imageRequestID)
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let viewController: FAMFullscreenViewController = FAMFullscreenViewController(selectedIndexPath: indexPath)
        viewController.fullscreenDataSource = self
        viewController.fullscreenDelegate = self
        viewController.showParallax = true
        self.presentViewController(viewController, animated: true, completion: nil)
    }
}

extension ViewController: FAMFullscreenViewControllerDataSource {
    func numberOfSections(inFullscreenViewController viewController: FAMFullscreenMainViewController) -> Int {
        return 1
    }

    func fullscreenViewController(viewController: FAMFullscreenMainViewController, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult?.count ?? 0
    }

    func fullscreenViewController(viewController: FAMFullscreenMainViewController, contentTypeAtIndexPath indexPath: NSIndexPath) -> FAMFullscreenContentType {
        guard let asset: PHAsset = self.fetchResult?.objectAtIndex(indexPath.row) as? PHAsset else {
            fatalError("asset get failed")
        }

        if asset.mediaType == PHAssetMediaType.Image {
            return FAMFullscreenContentType.Image
        } else if asset.mediaType == PHAssetMediaType.Video {
            return FAMFullscreenContentType.Video
        }
        return FAMFullscreenContentType.None
    }

    func fullscreenViewController(viewController: FAMFullscreenMainViewController, requestImageAtIndexPath indexPath: NSIndexPath, request: FAMFullscreenImageRequest) {
        guard let asset: PHAsset = self.fetchResult?.objectAtIndex(indexPath.row) as? PHAsset else {
            fatalError("asset get failed")
        }
        self.imageManager.requestImageForAsset(asset, targetSize: UIScreen.mainScreen().bounds.size, contentMode: PHImageContentMode.Default, options: nil) { (image: UIImage?, meta: [NSObject : AnyObject]?) in
            if let image: UIImage = image {
                request(result: FAMFullscreenImageRequestResult.Success(image))
            } else {
                request(result: FAMFullscreenImageRequestResult.Failure)
            }
        }
    }
}

extension ViewController: FAMFullscreenViewControllerDelegate {
    func fullscreenViewController(viewController: FAMFullscreenViewController, rectForIndexPath indexPath: NSIndexPath) -> CGRect {
        guard let layoutAttribute: UICollectionViewLayoutAttributes = self.collectionView.layoutAttributesForItemAtIndexPath(indexPath) else {
            return CGRect.zero
        }
        return self.collectionView.convertRect(layoutAttribute.frame, toView: nil)
    }

    func fullscreenViewController(viewController: FAMFullscreenViewController, thumbnailImageForIndexPath indexPath: NSIndexPath) -> UIImage? {
        guard let cell: ViewControllerCell = self.collectionView.cellForItemAtIndexPath(indexPath) as? ViewControllerCell else {
            return nil
        }

        return cell.imageView.image
    }
}
