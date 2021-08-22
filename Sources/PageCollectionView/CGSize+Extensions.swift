//
//  File.swift
//  
//
//  Created by Adam Wulf on 8/22/21.
//

import UIKit

extension CGSize {
    func boundingSize(for rotation: CGFloat) -> CGSize {
        var bounds = CGRect(origin: .zero, size: self)
        bounds = bounds.applying(CGAffineTransform(rotationAngle: rotation))
        return bounds.size
    }

    func scale(to targetDim: CGFloat, scaleUp: Bool) -> CGSize {
        if height > width {
            return scaleHeight(to: targetDim, scaleUp: scaleUp)
        }
        return scaleWidth(to: targetDim, scaleUp: scaleUp)
    }

    func scaleHeight(to targetHeight: CGFloat, scaleUp: Bool) -> CGSize {
        if scaleUp || height > targetHeight {
            return CGSize(width: targetHeight * width / height, height: targetHeight)
        }
        return self
    }

    func scaleWidth(to targetWidth: CGFloat, scaleUp: Bool) -> CGSize {
        if scaleUp || width > targetWidth {
            return CGSize(width: targetWidth, height: targetWidth * height / width)
        }
        return self
    }
}
