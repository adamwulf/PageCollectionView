//
//  IconView.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

public class IconView: UIView {
    let cols = 4
    let rows = 2

    public var progress: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        finishInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        finishInit()
    }

    private func finishInit() {
        var zIndex = rows * cols

        for _ in 0 ..< rows {
            for _ in 0 ..< cols {
                let page = UIView()
                page.layer.backgroundColor = UIColor.white.cgColor
                page.layer.borderColor = UIColor.black.cgColor
                page.layer.borderWidth = 1
                page.layer.zPosition = CGFloat(zIndex)
                addSubview(page)
                zIndex -= 1
            }
        }

        setNeedsLayout()
    }

    func interpolate(s: CGFloat, e: CGFloat, p: CGFloat) -> CGFloat {
        return s * p + e * (1 - p)
    }
}
