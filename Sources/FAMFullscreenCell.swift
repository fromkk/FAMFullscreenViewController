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
    private (set) public lazy var viewController: FAMFullscreenContentViewController = {
        let viewController: FAMFullscreenContentViewController = FAMFullscreenContentViewController()
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        return viewController
    }()

    /// image
    public weak var image: UIImage? {
        didSet {
            self.viewController.image = self.image
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(self.viewController.view)
        self.contentView.addConstraints([
            NSLayoutConstraint(item: self.viewController.view, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.viewController.view, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.viewController.view, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: self.viewController.view, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0),
        ])
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
