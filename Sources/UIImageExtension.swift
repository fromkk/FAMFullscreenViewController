//
//  UIImageExtension.swift
//  FAMFullscreenViewController
//
//  Created by Kazuya Ueoka on 2016/07/27.
//  Copyright © 2016年 TimersInc. All rights reserved.
//

import UIKit

extension UIImageView {
    func _famFullScreenSizeForAspectFill(viewSize: CGSize) -> CGSize {
        guard let image = image else {
            return .zero
        }

        let size = image.size
        let screenSize = viewSize

        let imageAspect: CGFloat = size.height / size.width
        let screenAspect: CGFloat = screenSize.height / screenSize.width

        if imageAspect < screenAspect {
            // 横長の画像
            let ratio: CGFloat = size.height / screenSize.height
            return CGSize(width: size.width / ratio, height: screenSize.height)
        } else {
            // 縦長の画像
            let ratio: CGFloat = size.width / screenSize.width
            return CGSize(width: screenSize.width, height: size.height / ratio)
        }
    }

    func _famFullScreenSizeForAspectFit(viewSize: CGSize) -> CGSize {
        guard let image = image else {
            return .zero
        }

        let size = image.size
        let screenSize = viewSize

        let imageAspect: CGFloat = size.height / size.width
        let screenAspect: CGFloat = screenSize.height / screenSize.width

        if imageAspect < screenAspect {
            // 横長の画像
            let ratio: CGFloat = size.width / screenSize.width
            return CGSize(width: screenSize.width, height: size.height / ratio)
        } else {
            // 縦長の画像
            let ratio: CGFloat = size.height / screenSize.height
            return CGSize(width: size.width / ratio, height: screenSize.height)
        }
    }
}
