//
//  CGSize+Extensions.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

extension CGSize {

    /**
     * Calculate the size of a box that will inscribe a containing box of input width. The incribed box
     * @param ratio the ratio of height / width for the box that will be inscribed
     * @param rotation the angle that the incribed box is rotated
     * @param fitWidth the width of the box that contains the inscribed box
     *
     * to do that, if W is the scaled width of the page, H is the
     * scaled height of of the page, and FW is the fitWidth, and
     * A is the angle that the page has been rotated, then:
     *
     * FW == cos(A) * W + sin(A) * H
     * and we know that H / W == R, so
     * FW == cos(A) * W + sin(A) * W * R
     * FW == (cos(A) + sin(A) * R) * W
     * W == SW / (cos(A) + sin(A) * R)
     * H = W * R
     *
     * care needs to be taken to use the ABS() of the sine and cosine
     * otherwise the sum of the two will cancel out and leave us with
     * the wrong ratio. Signs of these probably matter to tell us left/right
     * or some other thing we can ignore.
     */
    init(forInscribedWidth width: CGFloat, ratio: CGFloat, rotation: CGFloat) {
        let newWidth = width / (abs(sin(rotation) * ratio) + abs(cos(rotation)))

        self.init(width: abs(newWidth), height: abs(newWidth * ratio))
    }

    /**
     * FH == cos(A) * H + sin(A) * W
     * and we know that H / W == R, so
     * FH == cos(A) * H + sin(A) * H / R
     * FH == (cos(A) + sin(A) / R) * H
     * H == FH / (cos(A) + sin(A) / R)
     * H = W * R
     */
    init(forInscribedHeight height: CGFloat, ratio: CGFloat, rotation: CGFloat) {
        let newHeight = height / (abs(cos(rotation)) + abs(sin(rotation) / ratio))
        self.init(width: abs(newHeight / ratio), height: abs(newHeight))
    }

    func scale(by factor: CGFloat) -> CGSize {
        return CGSize(width: width * factor, height: height * factor)
    }

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
