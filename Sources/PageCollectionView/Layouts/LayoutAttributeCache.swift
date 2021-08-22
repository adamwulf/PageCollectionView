//
//  LayoutAttributeCache.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

class LayoutAttributeCache {
    var frame: CGRect = .null
    private(set) var visibleItems: [UICollectionViewLayoutAttributes] = []
    private(set) var hiddenItems: [UICollectionViewLayoutAttributes] = []
    var allItems: [UICollectionViewLayoutAttributes] {
        return visibleItems + hiddenItems
    }

    func append(attributes: UICollectionViewLayoutAttributes) {
        frame = frame.union(attributes.frame)

        if attributes.isHidden {
            hiddenItems.append(attributes)
        } else {
            visibleItems.append(attributes)
        }
    }
}
