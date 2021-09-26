//
//  PageLayout.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

class PageLayoutAttributes: UICollectionViewLayoutAttributes {
    var boundingSize: CGSize = .zero
    var scale: CGFloat = 0
}

@objc public protocol UICollectionViewDelegatePageLayout: UICollectionViewDelegateShelfLayout {
    @objc optional func collectionView(_ collectionView: UICollectionView,
                                       layout: PageLayout,
                                       zoomScaleForIndexPath indexPath: IndexPath) -> CGFloat
}

public class PageLayout: GridLayout {
    public enum Direction: UInt {
        case horizontal
        case vertical
    }

    public var pageDelegate: UICollectionViewDelegatePageLayout? {
        return collectionView?.delegate as? UICollectionViewDelegatePageLayout
    }

    public var fitWidth: Bool = true
    public var direction: Direction = .vertical

    internal var startingPercentOffset: CGPoint = .zero
    internal var gestureRecognizer: PinchVelocityGestureRecognizer?

    private var boundingSize: CGSize = .zero
    private var scale: CGFloat = 0
    private var sectionOffset: CGFloat = 0
    private var sectionHeight: CGFloat = 0
    private var sectionWidth: CGFloat = 0
    // track the header height so that we know when the bounds are within/out of the headers
    private var headerHeight: CGFloat = 0
    // track the orthogonal dimention from scroll, so that when it changes we can invalidate the header attributes
    private var lastBoundsMinDim: CGFloat = 0
    private var pageCache: [UICollectionViewLayoutAttributes] = []

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 40, right: 40)
    }

    public override init(section: Int) {
        super.init(section: section)
        sectionInsets = UIEdgeInsets(top: 10, left: 10, bottom: 40, right: 40)
    }

    override public var bounceHorizontal: Bool {
        return direction == .horizontal
    }

    public override var bounceVertical: Bool {
        return direction == .vertical
    }

    // MARK: - UICollectionViewLayout

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // Check if our bounds have changed enough so that we need to re-align our headers
        // with the newly visible rect of the content
        var currMinBoundsDim = lastBoundsMinDim
        let insets = collectionView?.safeAreaInsets ?? .zero

        if direction == .vertical && newBounds.minY < headerHeight + insets.top {
            currMinBoundsDim = newBounds.minX
        } else if direction == .horizontal && newBounds.minX < headerHeight + insets.left {
            currMinBoundsDim = newBounds.minY
        }

        if currMinBoundsDim != lastBoundsMinDim {
            lastBoundsMinDim = currMinBoundsDim
            invalidateLayout(with: invalidationContext(forBoundsChange: newBounds))
        }

        // the above handles conditionally invalidating the layout from this bounds change,
        // our [super] will handle invalidating the entire layout from the change
        return super.shouldInvalidateLayout(forBoundsChange: newBounds)
    }

    public override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        // The only thing we need to conditionally invalidate because of a bounds change is our header
        let context = super.invalidationContext(forBoundsChange: newBounds)
        let vHeaderPath = IndexPath(row: 0, section: section)
        let hHeaderPath = IndexPath(row: 1, section: section)

        context.invalidateSupplementaryElements(ofKind: UICollectionView.elementKindSectionHeader, at: [vHeaderPath, hHeaderPath])

        return context
    }

    public override var collectionViewContentSize: CGSize {
        let contentSize = super.collectionViewContentSize
        let insets = collectionView?.safeAreaInsets ?? .zero

        if direction == .vertical {
            return CGSize(width: max(sectionWidth, contentSize.width) + insets.left + insets.right, height: sectionHeight)
        } else {
            return CGSize(width: max(sectionWidth, contentSize.width), height: sectionHeight + insets.top + insets.bottom)
        }
    }

    public override func invalidateLayout() {
        super.invalidateLayout()

        pageCache.removeAll()
    }

    public override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        if direction == .vertical {
            let header = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                              at: IndexPath(row: 0, section: section))
            sectionOffset = header?.frame.minY ?? 0
        } else {
            sectionOffset = 0
        }

        sectionWidth = 0
        sectionHeight = 0

        let collectionViewBounds = collectionView.bounds
        let insets = collectionView.safeAreaInsets
        let maxDim: CGFloat

        if direction == .vertical {
            maxDim = collectionViewBounds.width - insets.left - insets.right
        } else {
            maxDim = collectionViewBounds.height - insets.top - insets.bottom
        }

        let kMaxDim = maxDim
        var offset: CGFloat = 0
        let kItemCount = collectionView.numberOfItems(inSection: section)
        var scaledMaxDim = kMaxDim

        // Calculate the header section size, if any
        var headerHeight = pageDelegate?.collectionView?(collectionView, layout: self, heightForHeaderInSection: section) ?? defaultHeaderHeight

        self.headerHeight = headerHeight

        // track the location of the bounds in the direction orthogonal to the scroll
        if direction == .vertical {
            lastBoundsMinDim = collectionViewBounds.minX
        } else {
            lastBoundsMinDim = collectionViewBounds.minY
        }

        // Layout the header, if any
        if headerHeight > 0 {
            let vHeaderAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                                                with: IndexPath(row: 0, section: section))
            let hHeaderAttrs = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                                                with: IndexPath(row: 1, section: section))

            vHeaderAttrs.bounds = CGRect(x: 0, y: 0, width: collectionViewBounds.width - insets.left - insets.right, height: headerHeight)
            vHeaderAttrs.center = CGPoint(x: collectionViewBounds.midX, y: headerHeight / 2)
            vHeaderAttrs.alpha = direction == .vertical ? 1 : 0

            hHeaderAttrs.bounds = CGRect(x: 0, y: 0, width: collectionViewBounds.height - insets.top - insets.bottom, height: headerHeight)
            hHeaderAttrs.center = CGPoint(x: headerHeight / 2, y: collectionViewBounds.midY + insets.top / 2)
            hHeaderAttrs.transform = .init(rotationAngle: -CGFloat.pi / 2)
            hHeaderAttrs.alpha = direction == .horizontal ? 1 : 0

            pageCache.append(vHeaderAttrs)
            pageCache.append(hHeaderAttrs)

            offset += headerHeight
        }

        if direction == .vertical {
            offset += sectionInsets.top
        } else {
            offset += sectionInsets.left
        }

        // Layout each page
        for pageIdx in 0 ..< kItemCount {
            let indexPath = IndexPath(row: pageIdx, section: section)

            if let shouldIgnore = pageDelegate?.collectionView?(collectionView, layout: self, shouldIgnoreItemAtIndexPath: indexPath),
               shouldIgnore,
               let hiddenAttributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes {
                if direction == .vertical {
                    hiddenAttributes.center = CGPoint(x: hiddenAttributes.center.x, y: offset)
                } else {
                    hiddenAttributes.center = CGPoint(x: sectionWidth, y: hiddenAttributes.center.y)
                }
                hiddenAttributes.alpha = 0
                pageCache.append(hiddenAttributes)
                continue
            }

            guard
                let object = datasource?.collectionView(collectionView, layout: self, objectAtIndexPath: indexPath)
            else {
                continue
            }

            if let itemAttrs = layoutPage(object, at: offset, for: indexPath, kMaxDim: kMaxDim) {
                let boundingSize = itemAttrs.boundingSize
                let scale = itemAttrs.scale

                pageCache.append(itemAttrs)

                // update our offset to account for this page
                if direction == .vertical {
                    offset += boundingSize.height * scale
                } else {
                    offset += boundingSize.width * scale
                }

                // and track our max orthogonal dimension as well
                if direction == .vertical {
                    scaledMaxDim = max(scaledMaxDim, boundingSize.width * scale)
                    sectionWidth = max(sectionWidth, kMaxDim * scale)
                } else {
                    scaledMaxDim = max(scaledMaxDim, boundingSize.height * scale)
                    sectionHeight = max(sectionHeight, kMaxDim * scale)
                }
            }
        }

        // Determine the max size in each dimension for this layout
        if direction == .vertical {
            if scaledMaxDim < sectionWidth {
                // all of our pages were smaller than the width of our collection view.
                // center these items in the available space left over. This lets us
                // keep the collection view content size the same as its width for as
                // long as possible when zooming collections of smaller pages
                let leftBump = (sectionWidth - scaledMaxDim) / 2

                for attrs in pageCache {
                    var center = attrs.center
                    center.x -= leftBump
                    attrs.center = center
                }

                sectionWidth = scaledMaxDim
            }
        } else if direction == .horizontal {
            if scaledMaxDim < sectionHeight {
                // all of our pages were smaller than the width of our collection view.
                // center these items in the available space left over. This lets us
                // keep the collection view content size the same as its width for as
                // long as possible when zooming collections of smaller pages
                let topBump = (sectionHeight - scaledMaxDim) / 2

                for attrs in pageCache {
                    var center = attrs.center
                    center.y -= topBump
                    attrs.center = center
                }

                sectionHeight = scaledMaxDim
            }
        }

        if direction == .vertical {
            offset += sectionInsets.bottom
            sectionHeight = offset
        } else {
            offset += sectionInsets.right
            sectionWidth = offset
        }
    }

    func layoutPage(_ object: ShelfLayoutObject, at offset: CGFloat, for indexPath: IndexPath, kMaxDim: CGFloat) -> PageLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }

        let idealSize = object.idealSize
        let rotation = object.rotation
        let physicalSize = idealSize.boundingSize(for: rotation).scale(by: object.physicalScale)
        let insets = collectionView.safeAreaInsets

        // scale the page so that if fits in screen when its fully rotated.
        // This is the screen-aligned box that contains our rotated page
        let boundingSize: CGSize
        var itemSize: CGSize

        if direction == .vertical {
            boundingSize = physicalSize.scaleWidth(to: kMaxDim, scaleUp: fitWidth)

            // now we need to find the unrotated size of the page that
            // fits in the above box when its rotated.
            //
            // If the page is the exact same size as the screen, we rotate it
            // and then we have to shrink it so that the corners of the page
            // are always barely touching the screen edges.
            itemSize = CGSize(forInscribedWidth: boundingSize.width, ratio: idealSize.height / idealSize.width, rotation: rotation)
        } else {
            boundingSize = physicalSize.scaleHeight(to: kMaxDim, scaleUp: fitWidth)
            itemSize = CGSize(forInscribedHeight: boundingSize.height, ratio: idealSize.height / idealSize.width, rotation: rotation)
        }

        // Next, scale the page to account for our delegate's pinch-to-zoom.
        let scale: CGFloat = pageDelegate?.collectionView?(collectionView, layout: self, zoomScaleForIndexPath: indexPath) ?? 1
        let diff: CGFloat

        if direction == .vertical {
            diff = (kMaxDim - itemSize.width) / 2.0 * scale + insets.left
        } else {
            diff = (kMaxDim - itemSize.height) / 2.0 * scale + insets.top
        }

        // set all the attributes
        let itemAttrs = PageLayoutAttributes(forCellWith: indexPath)
        let altDiff: CGFloat
        var frame: CGRect

        if direction == .vertical {
            altDiff = (itemSize.height - boundingSize.height) / 2.0 * scale
            frame = CGRect(x: diff, y: offset - altDiff, width: itemSize.width, height: itemSize.height)
        } else {
            altDiff = (itemSize.width - boundingSize.width) / 2.0 * scale
            frame = CGRect(x: offset - altDiff, y: diff, width: itemSize.width, height: itemSize.height)
        }

        // For forcing the UICollectionViewBug described below.
        // this doesn't need to be included, as a 180 degree
        // rotation will also do this, but forcing it will
        // help make sure our fix described below will always work
        frame.origin.x -= -0.00000000000011368683772161603

        itemAttrs.frame = frame

        var transform: CGAffineTransform = .identity
            .translatedBy(x: -itemSize.width / 2, y: -itemSize.height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: itemSize.width / 2, y: itemSize.height / 2)

        if rotation != 0 {
            transform = transform.rotated(by: rotation)
        }

        itemAttrs.boundingSize = boundingSize
        itemAttrs.scale = scale
        itemAttrs.alpha = 1
        itemAttrs.isHidden = false
        itemAttrs.transform = transform

        // This block is for the UICollectionViewBug, where if a frame of an item
        // has a tiny offset from a round pixel, then it might disappear from the
        // collection view altogether.
        // Filed at FB7415012
        let bumpX = itemAttrs.frame.minX - floor(itemAttrs.frame.minX)
        let bumpY = itemAttrs.frame.minY - floor(itemAttrs.frame.minY)
        itemAttrs.center = CGPoint(x: itemAttrs.center.x - bumpX, y: itemAttrs.center.y - bumpY)
        // end block

        return itemAttrs
    }

    // MARK: - Fetch Attributes

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var ret = pageCache.filter({ rect.intersects($0.frame) })

        for index in 0 ..< 2 where index < ret.count {
            // update our headers
            if ret[index].representedElementKind == UICollectionView.elementKindSectionHeader {
                let oldHeader = ret[index]
                guard
                    let newHeader = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                         at: oldHeader.indexPath)
                else {
                    continue
                }
                ret[index] = newHeader
            }
        }

        return ret
    }

    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                              at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else { return nil }
        // TODO: Why is the indexPath empty for supplementary views?
        guard !indexPath.isEmpty else { return nil }

        if indexPath.section == section {
            for attrs in pageCache {
                if
                    attrs.representedElementCategory == .supplementaryView && attrs.indexPath == indexPath,
                    let ret = attrs.copy() as? UICollectionViewLayoutAttributes {
                    // center the attributes in the scrollable direction
                    let insets = collectionView.safeAreaInsets

                    if indexPath.row == 0 {
                        // asking for vertical header
                        if direction == .vertical {
                            let midDim = lastBoundsMinDim + collectionView.bounds.width / 2
                            ret.center = CGPoint(x: midDim + insets.left / 2 - insets.right / 2, y: headerHeight / 2)
                            ret.alpha = 1
                        } else {
                            ret.alpha = 0
                        }
                    } else {
                        // asking for horizontal header
                        if direction == .horizontal {
                            let midDim = lastBoundsMinDim + collectionView.bounds.height / 2
                            ret.center = CGPoint(x: headerHeight / 2, y: midDim + insets.top / 2 - insets.bottom / 2)
                            ret.alpha = 1
                        } else {
                            ret.alpha = 0
                        }
                    }

                    return ret
                }
            }
        }

        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section == section {
            for attrs in pageCache {
                if attrs.representedElementCategory == .cell && attrs.indexPath == indexPath {
                    return attrs
                }
            }
        }

        return super.layoutAttributesForItem(at: indexPath)
    }

    // MARK: - Content Offset

    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        let contentSize = collectionViewContentSize
        let viewSize = collectionView.bounds.size
        let insets = collectionView.safeAreaInsets
        var ret = CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)

        if let gestureRecognizer = gestureRecognizer {
            // the user is pinching to zoom the page. calculate an offset for our content
            // that will keep the pinch gesture in the same location of the zoomed page.
            // This method is called during zoom because the collection view is constantly
            // resetting its layout to a new page layout, so it transitions from page layout
            // to page layout, and uses this method to keep the offset where it needs to be
            let outerOffset = gestureRecognizer.location(in: collectionView.superview)
            // _startingPercentOffset is the % of our contentSize that should align to our gesture
            // startLocInContent is the point in the content that is exactly under the gesture
            // when the gesture begins.
            let startLocInContent = CGPoint(x: collectionViewContentSize.width * startingPercentOffset.x,
                                            y: collectionViewContentSize.height * startingPercentOffset.y)

            var targetLocInContent = startLocInContent

            // so remove the gesture's offset from the corner of the super view to the gesture,
            // as our contentOffset will need to be relative to that corner
            targetLocInContent.x -= outerOffset.x
            targetLocInContent.y -= outerOffset.y

            // If the user starts a pinch with two fingers, but then lifts a finger
            // the pinch gesture doesn't fail, but instead continues. By default,
            // the location of the gesture is the average of all touches, so this
            // makes the location jump around the screen as the user lifts and presses
            // down fingers mid-gesture. The MMPinchVelocityGestureRecognizer instead
            // handles this for us and returns a smooth locationInView: that accounts
            // for touches starting and stopping mid gesture. The `scaledAdjustment` property
            // is a CGPoint offset from teh gesture's location back to the initial
            // locationInView when the gesture first began. We can use this to
            // Adjust the content offset and keep the content under our fingers
            // throughout the pinch, even if the user 'walks' their fingers
            // down the screen resulting in a large scaledAdjustment.
            let scaledAdjustment = gestureRecognizer.scaledAdjustment

            targetLocInContent.x -= scaledAdjustment.x * max(1, gestureRecognizer.scale)
            targetLocInContent.y -= scaledAdjustment.y * max(1, gestureRecognizer.scale)

            // now that our content is aligned with our gesture,
            // clamp it to the edges of our content
            targetLocInContent.x = max(-insets.left, min(contentSize.width - viewSize.width, targetLocInContent.x))
            targetLocInContent.y = max(-insets.top, min(contentSize.height - viewSize.height, targetLocInContent.y))

            ret = targetLocInContent
        } else if direction == .horizontal,
                  let targetIndexPath = targetIndexPath {
            var locInContent: CGPoint

            if targetIndexPath.row == 0 {
                // for the first page, align it to the left of the screen
                locInContent = .zero
            } else {
                // for all other pages, align them to the center of the screen
                let attrs = layoutAttributesForItem(at: targetIndexPath)
                assert(attrs != nil, "Unable to find attributes for target index")
                let itemFrame = attrs?.frame ?? .zero
                let diff = max(0, (collectionView.bounds.width - itemFrame.width) / 2.0)

                locInContent = CGPoint(x: itemFrame.minX - diff, y: 0)
            }

            // clamp the offset so that we're not over/under scrolling our content size
            locInContent.x = max(-insets.left, min(contentSize.width - viewSize.width, locInContent.x))

            ret = locInContent
        } else if direction == .vertical,
                  let targetIndexPath = targetIndexPath {
            var locInContent: CGPoint

            if targetIndexPath.row == 0 {
                // align the first page to the top of the screen
                locInContent = .zero
            } else {
                // and align all other pages to the center of the screen
                let attrs = layoutAttributesForItem(at: targetIndexPath)
                assert(attrs != nil, "Unable to find attributes for target index")
                let itemFrame = attrs?.frame ?? .zero
                let diff = max(0, (collectionView.bounds.height - itemFrame.height) / 2.0)

                locInContent = CGPoint(x: 0, y: itemFrame.minY - diff)
            }

            // clamp the offset so that we're not over/under scrolling our content size
            locInContent.y = max(-insets.top, min(contentSize.height - viewSize.height, locInContent.y))

            ret = locInContent
        }

        if ret.x == .infinity {
            ret = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }

        var bounds = collectionView.bounds
        bounds.origin = ret

        // check if we need to invalidate headesr for this offset
        _ = shouldInvalidateLayout(forBoundsChange: bounds)

        return ret
    }
}
