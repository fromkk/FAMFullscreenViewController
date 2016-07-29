//
//  FAMFullscreenCell.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/26.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit

public class FAMFullscreenCell: UICollectionViewCell {
    public static let cellIdentifier: String = "FAMFullscreenCell"
    public var contentType: FAMFullscreenContentType = FAMFullscreenContentType.None {
        didSet {
            //TODO: display play video button when contentType is Video
        }
    }

    /// content view controller
    internal (set) public var viewController: FAMFullscreenContentViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()

            if let viewController: FAMFullscreenContentViewController = self.viewController {
                self.contentView.addSubview(viewController.view)
                self.contentView.addConstraints([
                    NSLayoutConstraint(item: viewController.view, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0),
                    NSLayoutConstraint(item: viewController.view, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0),
                    NSLayoutConstraint(item: viewController.view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0),
                    NSLayoutConstraint(item: viewController.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0),
                    ])
                viewController.view.translatesAutoresizingMaskIntoConstraints = false
            }

            if let image: UIImage = self.image {
                self.viewController?.image = image
            }
        }
    }

    /// image
    public weak var image: UIImage? {
        didSet {
            self.viewController?.image = self.image
        }
    }
}
