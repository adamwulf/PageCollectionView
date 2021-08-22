//
//  GridLayout.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

public class GridLayout: ShelfLayout {
    let section: Int
    var itemSpacing: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    private var gridCache: [UICollectionViewLayoutAttributes] = []
    private var sectionHeight: CGFloat = 0
    private var yOffsetForTransition: CGFloat = 0

    init(section: Int) {
        self.section = section
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    func alignInRow(items: [UICollectionViewLayoutAttributes],
                    maxItemHeight: CGFloat,
                    rowWidth: CGFloat,
                    yOffset: CGFloat,
                    stretchWidth shouldStretch: Bool,
                    widthDiff widthDiffInOut: inout CGFloat) -> [UICollectionViewLayoutAttributes] {
        var yOffset = yOffset
        let stretchWidthDiff = collectionViewContentSize.width - rowWidth - sectionInsets.left - sectionInsets.right
        var widthDiff = shouldStretch ? stretchWidthDiff : widthDiffInOut
        widthDiff = min(stretchWidthDiff, widthDiff)
        let spacing = items.count > 1 ? widthDiff / CGFloat(items.count - 1) : 0
        yOffset += maxItemHeight / 2.0 // so that the yoffset is based on the center instead of the top

        for (index, obj) in items.enumerated() {
            var center = obj.center
            center.x += sectionInsets.left
            center.x += spacing * CGFloat(index)
            center.y = yOffset
            obj.center = center
        }

        widthDiffInOut = widthDiff

        return items
    }

    // MARK: - UICollectionViewLayout

    public override var collectionViewContentSize: CGSize {
        let contentSize = super.collectionViewContentSize

        return CGSize(width: contentSize.width, height: sectionHeight)
    }

    public func invalidationContextForTransition() -> UICollectionViewLayoutInvalidationContext {
        let context = UICollectionViewLayoutInvalidationContext()

        guard let collectionView = collectionView else { return context }

        let sectionCount = collectionView.numberOfSections
        var headers: [IndexPath] = []
        var items: [IndexPath] = []
        for section in 0 ..< sectionCount {
            headers.append(IndexPath(row: 0, section: section))
            guard let sectionCache = shelfAttributes(for: section) else { continue }
            items.append(contentsOf: sectionCache.visibleItems.map({ $0.indexPath }))
        }

        context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: headers)
        context.invalidateItems(at: items)

        return context
    }

    public override func invalidateLayout() {
        super.invalidateLayout()

        gridCache.removeAll()
    }

    public override func prepare() {
        super.prepare()

        // Call [super] to get the attributes of our header in shelf mode. This will give us our section offset
        // in shelf mode, which we'll use to adjust all other items so that our grid section will appear at 0,0
        guard
            let collectionView = collectionView,
            let headerAttrs = super.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                     at: IndexPath(row: 0, section: section))?.copy()
            as? UICollectionViewLayoutAttributes
        else {
            return
        }

        var headerFrame = headerAttrs.frame
        var yOffset: CGFloat = 0
        let pageCount = collectionView.numberOfItems(inSection: section)
        var maxItemHeight: CGFloat = 0
        let headerHeight: CGFloat = headerFrame.height

        if headerHeight > 0 {
            headerFrame.origin.y = yOffset
            headerAttrs.frame = headerFrame

            gridCache.append(headerAttrs)

            yOffset += headerHeight
        }

        var xOffset: CGFloat = sectionInsets.left
        yOffset += sectionInsets.top
        // a running list of all item attributes in the calculated row
        var attributesPerRow: [UICollectionViewLayoutAttributes] = []
        // track each rowWidth so that we can center all of the items in the row for equal left/right margins
        var rowWidth: CGFloat = 0
        // track the row's last item's width, so that on our very last row we can see if we're within ~ 1 item from the edge
        var lastItemWidth: CGFloat = 0
        var widthDiffPerItem: CGFloat = 0

        // Calculate the size of each row
        for pageIndex in 0 ..< pageCount {
            let indexPath = IndexPath(row: pageIndex, section: section)
            guard let object = datasource?.collectionView(collectionView, layout: self, objectAtIndexPath: indexPath) else { continue }
            let rotation = object.rotation
            let idealSize = object.idealSize.scale(to: maxDim, scaleUp: false)
            let boundingSize = idealSize.boundingSize(for: rotation)

            // can it fit on this row?
            if xOffset + boundingSize.width + sectionInsets.right > collectionViewContentSize.width {
                // the row is done, remove the next item spacing. the item spacing do not sum with the sectionInsets,
                // so the right+left spacing are added after every item to separate it from the following item. but there
                // is no following item, so remove those trailing margins.
                rowWidth -= itemSpacing.right + itemSpacing.left
                // now realign all the items into their row so that they stretch full width
                gridCache.append(contentsOf: alignInRow(items: attributesPerRow, maxItemHeight: maxItemHeight, rowWidth: rowWidth, yOffset: yOffset, stretchWidth: true, widthDiff: &widthDiffPerItem))

                widthDiffPerItem /= CGFloat(attributesPerRow.count - 1)

                attributesPerRow.removeAll()

                yOffset += maxItemHeight + itemSpacing.bottom + itemSpacing.top
                xOffset = sectionInsets.left
                maxItemHeight = 0
                rowWidth = 0
            }

            // track this row's tallest item, so we can vertically center them all when the row is done
            maxItemHeight = max(maxItemHeight, boundingSize.height)

            // set all the attributes
            let itemAttrs = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            itemAttrs.bounds = CGRect(origin: .zero, size: idealSize)
            itemAttrs.center = CGPoint(x: rowWidth + boundingSize.width / 2, y: 0)
            itemAttrs.zIndex = pageCount - pageIndex
            itemAttrs.alpha = 1
            itemAttrs.isHidden = false

            lastItemWidth = boundingSize.width
            rowWidth += boundingSize.width + itemSpacing.right + itemSpacing.left
            xOffset += boundingSize.width + itemSpacing.right + itemSpacing.left

            if rotation != 0 {
                itemAttrs.transform = .init(rotationAngle: rotation)
            } else {
                itemAttrs.transform = .identity
            }

            if delegate?.collectionView?(collectionView, layout: self, shouldIgnoreItemAtIndexPath: indexPath) ?? false {
                itemAttrs.alpha = 0
                itemAttrs.isHidden = true
            }

            attributesPerRow.append(itemAttrs)
        }

        if !attributesPerRow.isEmpty {
            // we should stretch the last row if we're close to the edge anyways
            var widthDiff = widthDiffPerItem * CGFloat(attributesPerRow.count - 1)
            let stretch = xOffset + lastItemWidth + sectionInsets.right > collectionViewContentSize.width
            rowWidth -= itemSpacing.right + itemSpacing.left

            gridCache.append(contentsOf: alignInRow(items: attributesPerRow, maxItemHeight: maxItemHeight, rowWidth: rowWidth, yOffset: yOffset, stretchWidth: stretch, widthDiff: &widthDiff))
        } else {
            // remove the top margin for the next row, since there is no next row
            yOffset -= itemSpacing.top
        }

        yOffset += maxItemHeight + sectionInsets.bottom

        sectionHeight = yOffset
    }
}
