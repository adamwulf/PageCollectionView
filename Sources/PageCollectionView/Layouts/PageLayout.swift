//
//  PageLayout.swift
//  
//
//  Created by Adam Wulf on 8/22/21.
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

    var fitWidth: Bool = true
    var direction: Direction = .vertical
    var startingPercentOffset: CGPoint = .zero
    var gestureRecognizer: PinchVelocityGestureRecognizer?

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
        headerHeight = pageDelegate?.collectionView?(collectionView, layout: self, heightForHeaderInSection: section) ?? defaultHeaderHeight

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

            guard let object = datasource?.collectionView(collectionView, layout: self, objectAtIndexPath: indexPath) else { continue }

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
        return PageLayoutAttributes()
    }
}
