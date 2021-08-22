//
//  LayoutAttributeCache.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

public class LayoutAttributeCache {
    public var frame: CGRect = .null
    private(set) public var visibleItems: [UICollectionViewLayoutAttributes] = []
    private(set) public var hiddenItems: [UICollectionViewLayoutAttributes] = []
    public var allItems: [UICollectionViewLayoutAttributes] {
        return visibleItems + hiddenItems
    }

    public func append(attributes: UICollectionViewLayoutAttributes) {
        frame = frame.union(attributes.frame)

        if attributes.isHidden {
            hiddenItems.append(attributes)
        } else {
            visibleItems.append(attributes)
        }
    }
}
