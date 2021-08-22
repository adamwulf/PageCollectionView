//
//  ShelfLayout.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

/// Similar  to UICollectionViewDelegateFlowLayout, these delegate method will be used by the layout
/// for item specific properties. If they are not implemented, then defaultHeaderSize or defaultItemSize
/// will be used instead.
public protocol UICollectionViewDataSourceShelfLayout: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, layout: ShelfLayout, objectAtIndexPath: IndexPath) -> ShelfLayoutObject
}

/// Similar  to UICollectionViewDelegateFlowLayout, these delegate method will be used by the layout
/// for item specific properties. If they are not implemented, then defaultHeaderSize or defaultItemSize
/// will be used instead.
@objc public protocol UICollectionViewDelegateShelfLayout: UICollectionViewDelegate {
    @objc optional func collectionView(_ collectionView: UICollectionView, layout: ShelfLayout, heightForHeaderInSection: Int) -> CGFloat
    @objc optional func collectionView(_ collectionView: UICollectionView, layout: ShelfLayout, shouldIgnoreItemAtIndexPath: IndexPath) -> Bool
}

public class ShelfLayout: UICollectionViewLayout {

    // MARK: - Properties

    public var defaultHeaderHeight: CGFloat = 50
    public var maxDim: CGFloat = 140
    public var sectionInsets: UIEdgeInsets = UIEdgeInsets(top: 10, left: 40, bottom: 40, right: 40)
    public var pageSpacing: UInt = 40

    public var targetIndexPath: IndexPath?
    public var delegate: UICollectionViewDelegateShelfLayout? {
        return collectionView?.delegate as? UICollectionViewDelegateShelfLayout
    }
    public var datasource: UICollectionViewDataSourceShelfLayout? {
        guard let datasource = collectionView?.dataSource as? UICollectionViewDataSourceShelfLayout else {
            fatalError("CollectionView data source must conform to UICollectionViewDataSourceShelfLayout")
        }
        return datasource
    }

    public let bounceVertical = true
    public let bounceHorizontal = false

    // MARK: - Private Properties

    private var headerCache: [UICollectionViewLayoutAttributes] = []
    private var itemCache: [UICollectionViewLayoutAttributes] = []
    private var shelfCache: [LayoutAttributeCache] = []
    private var contentHeight: CGFloat = 0
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - insets.left - insets.right
    }

    // MARK: - Helpers

    public func shelfAttributes(for section: Int) -> LayoutAttributeCache? {
        if section < shelfCache.count {
            return shelfCache[section]
        }
        return nil
    }

    // MARK: - UICollectionViewLayout

    override public func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return collectionView?.bounds.size != newBounds.size
    }

    override public func invalidateLayout() {
        super.invalidateLayout()

        shelfCache.removeAll()
        headerCache.removeAll()
        itemCache.removeAll()
    }

    override public var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    override public func prepare() {
        guard
            let collectionView = collectionView,
            let datasource = datasource,
            shelfCache.isEmpty else { return }

        var yOffset: CGFloat = 0

        for section in 0 ..< collectionView.numberOfSections {
            let pageCount = collectionView.numberOfItems(inSection: section)
            var maxItemHeight: CGFloat = 0
            let sectionCache = LayoutAttributeCache()
            let headerHeight = delegate?.collectionView?(collectionView, layout: self, heightForHeaderInSection: section) ?? defaultHeaderHeight

            if headerHeight > 0 {
                let headerAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                                                   with: IndexPath(row: 0, section: section))
                headerAttrs.frame = CGRect(x: 0, y: yOffset, width: collectionView.bounds.width, height: headerHeight)
                sectionCache.append(attributes: headerAttrs)
                headerCache.append(headerAttrs)
                yOffset += headerHeight
            }

            var xOffset: CGFloat = sectionInsets.left
            yOffset += sectionInsets.top
            var didFinish = false

            // Calculate the size of each row
            for pageIndex in 0 ..< pageCount {
                let indexPath = IndexPath(row: pageIndex, section: section)
                let object = datasource.collectionView(collectionView, layout: self, objectAtIndexPath: indexPath)
                var itemSize = object.idealSize
                let rotation = object.rotation
                let heightRatio = itemSize.height / itemSize.width

                // calculate the dimensions of each item so that it fits within itemSize

                if itemSize.height <= itemSize.width && itemSize.width > maxDim {
                    itemSize.height = maxDim * heightRatio
                    itemSize.width = maxDim
                } else if itemSize.height >= itemSize.width && itemSize.height > maxDim {
                    itemSize.height = maxDim
                    itemSize.width = maxDim / heightRatio
                }

                let boundingSize = itemSize.boundingSize(for: rotation)
                maxItemHeight = max(maxItemHeight, boundingSize.height)

                let itemAttrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                itemAttrs.bounds = CGRect(origin: .zero, size: itemSize)
                itemAttrs.zIndex = pageCount - pageIndex
                itemAttrs.center = CGPoint(x: xOffset + itemSize.width / 2, y: yOffset + boundingSize.height / 2)

                if rotation != 0 {
                    itemAttrs.transform = .init(rotationAngle: rotation)
                } else {
                    itemAttrs.transform = .identity
                }

                // we've finished our row if the item would step into our section inset area.
                // we need to || because our xOffset is going to be randomly distributed after
                // this item, and our inequality won't always be true after the first hidden item
                didFinish = didFinish || xOffset + itemSize.width >= collectionViewContentSize.width - sectionInsets.right

                if didFinish {
                    itemAttrs.alpha = 0
                    itemAttrs.isHidden = true
                    let allowedWidth = collectionViewContentSize.width - sectionInsets.left - sectionInsets.right
                    xOffset = CGFloat.random(in: 0 ..< allowedWidth - itemSize.width)
                } else {
                    itemAttrs.alpha = 1
                    itemAttrs.isHidden = false
                    xOffset += CGFloat(pageSpacing)
                }

                if delegate?.collectionView?(collectionView, layout: self, shouldIgnoreItemAtIndexPath: indexPath) ?? false {
                    itemAttrs.alpha = 0
                }

                sectionCache.append(attributes: itemAttrs)
                itemCache.append(itemAttrs)
            }

            shelfCache.append(sectionCache)

            yOffset += maxItemHeight + sectionInsets.bottom
        }

        contentHeight = yOffset
    }

    // MARK: - Fetch Attributes

    override public func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let firstIndex = shelfCache.firstIndex(where: { obj in
                rect.intersects(obj.frame)
            }),
            let lastIndex = shelfCache.lastIndex(where: { obj in
                rect.intersects(obj.frame)
            })
        else {
            return []
        }

        // get the subarray of our first -> last index and return the visibleItems in those rows
        return shelfCache[firstIndex...lastIndex].flatMap({ $0.visibleItems })
    }

    override public func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return headerCache.first(where: { $0.indexPath == indexPath })
    }

    override public func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return itemCache.first(where: { $0.indexPath == indexPath })
    }

    // MARK: - Content Offset

    override public func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard
            let targetIndexPath = targetIndexPath,
            let collectionView = collectionView,
            let attrs = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: targetIndexPath)
                ?? layoutAttributesForItem(at: targetIndexPath),
            let shelfAttrs = shelfAttributes(for: targetIndexPath.section)
        else {
            return proposedContentOffset
        }

        let inset = -collectionView.safeAreaInsets.top
        let screenHeight = collectionView.bounds.height
        let size = collectionViewContentSize
        var targetY = attrs.frame.origin.y + inset

        // align to roughly middle of screen
        targetY -= (screenHeight - shelfAttrs.frame.height) / 5.0

        // clamp the target Y to our content size
        targetY = targetY < size.height - screenHeight ? targetY : size.height - screenHeight
        targetY = targetY < inset ? inset : targetY

        return CGPoint(x: 0, y: targetY)
    }
}
