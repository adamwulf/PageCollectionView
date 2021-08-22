//
//  HorizontalPageIconView.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

class HorizontalPageIconView: IconView {
    override public func layoutSubviews() {
        let margin: CGFloat = 4
        let myWidth = bounds.width
        let myHeight = bounds.height
        let pageHeight = myHeight / CGFloat(rows)
        let pageWidth = myWidth / CGFloat(cols)
        let gridXStep = pageWidth
        let gridYStep = pageHeight
        let xOffset = pageWidth * CGFloat(rows * cols) - myWidth

        for row in 0 ..< rows {
            for col in 0 ..< cols {
                var pageFrame = CGRect(x: pageWidth * CGFloat(row * cols + col) - xOffset,
                                       y: (myHeight - pageHeight) / 2.0,
                                       width: pageWidth,
                                       height: pageHeight)
                pageFrame = pageFrame.insetBy(dx: margin, dy: margin)

                var gridFrame = CGRect(x: gridXStep * CGFloat(col), y: gridYStep * CGFloat(row), width: pageWidth, height: pageHeight)
                gridFrame = gridFrame.insetBy(dx: margin, dy: margin)

                let page = subviews[row * cols + col]

                let final = CGRect(x: interpolate(s: gridFrame.minX, e: pageFrame.minX, p: progress),
                                   y: interpolate(s: gridFrame.minY, e: pageFrame.minY, p: progress),
                                   width: pageFrame.width,
                                   height: pageFrame.height)
                page.frame = final
            }
        }

        super.layoutSubviews()
    }
}
