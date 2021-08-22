//
//  GridIconView.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

public class GridIconView: IconView {
    override public func layoutSubviews() {
        let margin: CGFloat = 4
        let myWidth = bounds.width
        let myHeight = bounds.height
        let pageHeight = myHeight / CGFloat(rows)
        let pageWidth = myWidth / CGFloat(cols)
        let bookStep = (myWidth - pageWidth) / CGFloat(rows * cols - 1)
        let gridXStep = pageWidth
        let gridYStep = pageHeight

        for row in 0 ..< rows {
            for col in 0 ..< cols {
                var gridFrame = CGRect(x: gridXStep * CGFloat(col), y: gridYStep * CGFloat(row), width: pageWidth, height: pageHeight)
                gridFrame = gridFrame.insetBy(dx: margin, dy: margin)

                var bookFrame = CGRect(x: bookStep * CGFloat(row * cols + col),
                                       y: (myHeight - pageHeight) / 2.0,
                                       width: pageWidth,
                                       height: pageHeight)
                bookFrame = bookFrame.insetBy(dx: margin, dy: margin)

                let page = subviews[row * cols + col]
                let final = CGRect(x: interpolate(s: bookFrame.minX, e: gridFrame.minX, p: progress),
                                   y: interpolate(s: bookFrame.minY, e: gridFrame.minY, p: progress),
                                   width: bookFrame.width,
                                   height: bookFrame.height)
                page.frame = final
            }
        }

        super.layoutSubviews()
    }
}
