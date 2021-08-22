//
//  GridLayout.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

public class GridLayout: ShelfLayout {
    static private let AnimationBufferSpace: CGFloat = 200
    public let section: Int
    public var itemSpacing: UIEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

    private var gridCache: [UICollectionViewLayoutAttributes] = []
    private var sectionHeight: CGFloat = 0
    private var yOffsetForTransition: CGFloat = 0

    // MARK: - Init

    public init(section: Int) {
        self.section = section
        super.init()
    }

    required public init?(coder: NSCoder) {
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

            if shelfDelegate?.collectionView?(collectionView, layout: self, shouldIgnoreItemAtIndexPath: indexPath) ?? false {
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

    // MARK: - Transitions

    public override func prepareForTransition(to newLayout: UICollectionViewLayout) {
        super.prepareForTransition(to: newLayout)

        // transition from grid view /to/ another layout, or scrolling within grid view
        yOffsetForTransition = collectionView?.contentOffset.y ?? 0

        // invalidate all of the sections after our current section
        invalidateLayout(with: invalidationContextForTransition())
    }

    public override func prepareForTransition(from oldLayout: UICollectionViewLayout) {
        super.prepareForTransition(from: oldLayout)

        // transition from shelf view to grid view. When moving into the grid view,
        // the grid is always displayed at the very top of our content. if we ever
        // change to open to mid-grid from the shelf, then this will need to
        // compensate for that.
        yOffsetForTransition = 0

        invalidateLayout(with: invalidationContextForTransition())
    }

    // MARK: - Fetch Attributes

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return gridCache.filter({ rect.intersects($0.frame) })
    }

    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attrs = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)

        if let attrs = attrs {
            adjustLayoutAttributesForTransition(attrs)
        }

        if indexPath.section == section {
            attrs?.alpha = 1
            attrs?.isHidden = false
        } else {
            attrs?.alpha = 0
            attrs?.isHidden = true
        }

        return attrs
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section == section,
           let sectionAttributes = shelfAttributes(for: section) {
            for attrs in gridCache {
                if attrs.representedElementCategory == .cell && attrs.indexPath == indexPath {
                    if yOffsetForTransition > sectionAttributes.frame.height && attrs.frame.maxY < yOffsetForTransition {
                        // if we're in a transition from grid view, our content offset is larger than 0.
                        // and if the page's frames are offscreen above our starting offset, then don't
                        // load our grid layout, instead, load and adjust the shelf layout below
                        break
                    }

                    return attrs
                }
            }
        }

        // always [copy] from our [super] so that we don't accidentally modify our superclass's cached attributes
        let attrs = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes

        if let attrs = attrs {
            adjustLayoutAttributesForTransition(attrs)
        }

        if indexPath.section == section {
            attrs?.alpha = 1
            attrs?.isHidden = false
        } else {
            attrs?.alpha = 0
            attrs?.isHidden = true
        }

        return attrs
    }

    // MARK: - Helper

    func adjustLayoutAttributesForTransition(_ attrs: UICollectionViewLayoutAttributes) {
        // The following attributes should only be requested when transitioning to/from
        // this layout. The [prepareForTransitionTo/FromLayout:] methods invalidate these
        // elements, which will cause their attributes to be updated just in time for
        // the transition. Otherwise all of these elements are offscreen and invisible
        var center = attrs.center
        if let sectionAttributes = shelfAttributes(for: section) {
            if attrs.indexPath.section <= section {
                // for all sections that are before our grid, we can align those sections
                // as if they've shifted straight up from the top of our grid
                center.y -= sectionAttributes.frame.minY
                center.y += max(0, yOffsetForTransition - sectionAttributes.frame.height - Self.AnimationBufferSpace)
            } else if attrs.indexPath.section > section {
                // for all sections after our grid, the goal is to have them pinch to/from
                // immediatley after the screen, regardless of our scroll position. To do
                // that, we invalidate all headers/items as the view scrolls so that they're
                // continually layout right after the end of the screen, and then in the same
                // layout as the shelf. this way, the transition will have them slide up
                // direction from the bottom edge of the screen
                let diff = attrs.frame.minY - sectionAttributes.frame.minY

                // start at the correct target offset for the grid view
                center.y = yOffsetForTransition
                // move to the bottom of the screen
                center.y += collectionView?.bounds.height ?? 0
                // adjust the header to be in its correct offset to its neighbors
                center.y += diff
                // since we're moving the center, adjust by height/2
                center.y += attrs.frame.height / 2
            }
        }

        attrs.center = center
    }

    // MARK: - Content Offset

    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard
            let collectionView = collectionView,
            let targetIndexPath = targetIndexPath
        else {
            return proposedContentOffset
        }

        // when pinching from PageLayout, we'd like to focus the grid view so that
        // the page is centered in the view. To do that, calculate that target page's
        // offset within our content, and return a content offset that will align
        // with the middle of the screen
        var p = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        guard let attrs = layoutAttributesForItem(at: targetIndexPath) else { return proposedContentOffset }
        let itemFrame = attrs.frame
        let diff = max(0, (collectionView.bounds.height - itemFrame.height) / 2)
        let inset = collectionView.safeAreaInsets.top
        let contentSize = collectionViewContentSize
        let viewSize = collectionView.bounds.size

        p.y = max(-inset, min(contentSize.height - viewSize.height, itemFrame.minY - diff - inset))

        return p
    }
}
