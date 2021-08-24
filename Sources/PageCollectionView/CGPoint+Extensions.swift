//
//  CGPoint+Extensions.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/23/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(sqDistance(to: point))
    }

    func sqDistance(to point: CGPoint) -> CGFloat {
        return (x - point.x) * (x - point.x) + (y - point.y) * (y - point.y)
    }
}
