//
//  imageView.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/29.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit

class ContentImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self._commonInit()
    }

    override init(image: UIImage?) {
        super.init(image: image)

        self._commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self._commonInit()
    }

    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)

        self._commonInit()
    }

    private func _commonInit() {
        self.backgroundColor = UIColor.clearColor()
    }
}
