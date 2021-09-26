//
//  PageCollectionView.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/23/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

@objc public protocol PageCollectionViewDelegate: UICollectionViewDelegate {
    @objc optional func collectionView(_ collectionView: PageCollectionView,
                                       willChangeToLayout newLayout: UICollectionViewLayout,
                                       fromLayout oldLayout: UICollectionViewLayout)
    @objc optional func collectionView(_ collectionView: PageCollectionView,
                                       didChangeToLayout newLayout: UICollectionViewLayout,
                                       fromLayout oldLayout: UICollectionViewLayout)
    @objc optional func collectionView(_ collectionView: PageCollectionView,
                                       didFinalizeTransitionLayout transitionLayout: UICollectionViewTransitionLayout)
}

public class PageCollectionView: UICollectionView {
    public var pageDelegate: PageCollectionViewDelegate?

    private(set) var activeTransitionLayout: UICollectionViewTransitionLayout?

    // MARK: - Layout Helpers

    /// Returns the current layout of the collection view. If the collectionview is in the middel of a transition layout,
    /// then the current layout of that transition layout is returned
    public var currentLayout: ShelfLayout? {
        if let transitionLayout = collectionViewLayout as? UICollectionViewTransitionLayout {
            return transitionLayout.currentLayout as? ShelfLayout
        } else {
            return collectionViewLayout as? ShelfLayout
        }
    }

    // MARK: - UICollectionView

    public override var collectionViewLayout: UICollectionViewLayout {
        get {
            super.collectionViewLayout
        }
        set {
            let previousLayout = collectionViewLayout

            if previousLayout is UICollectionViewTransitionLayout,
               newValue is UICollectionViewTransitionLayout {
                // Don't change layout during transition
                assertionFailure("Cannot change layout during collection view transition")
                return
            }

            pageDelegate?.collectionView?(self, willChangeToLayout: newValue, fromLayout: previousLayout)
            super.collectionViewLayout = newValue
            pageDelegate?.collectionView?(self, didChangeToLayout: newValue, fromLayout: previousLayout)
        }
    }

    public override func setCollectionViewLayout(_ layout: UICollectionViewLayout, animated: Bool) {
        let previousLayout = collectionViewLayout
        if previousLayout is UICollectionViewTransitionLayout {
            // Don't change layout during transition
            assertionFailure("Cannot change layout during collection view transition")
            return
        }

        pageDelegate?.collectionView?(self, willChangeToLayout: layout, fromLayout: previousLayout)

        super.setCollectionViewLayout(layout, animated: animated) { finished in
            if animated && finished {
                self.pageDelegate?.collectionView?(self, didChangeToLayout: layout, fromLayout: previousLayout)
            }
        }

        if !animated {
            pageDelegate?.collectionView?(self, didChangeToLayout: layout, fromLayout: previousLayout)
        }
    }

    public override func setCollectionViewLayout(_ layout: UICollectionViewLayout, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        let previousLayout = collectionViewLayout
        if previousLayout is UICollectionViewTransitionLayout {
            // Don't change layout during transition
            assertionFailure("Cannot change layout during collection view transition")
            return
        }

        pageDelegate?.collectionView?(self, willChangeToLayout: layout, fromLayout: previousLayout)

        super.setCollectionViewLayout(layout, animated: animated) { finished in
            if let completion = completion {
                completion(finished)
            }
            if animated && finished {
                self.pageDelegate?.collectionView?(self, didChangeToLayout: layout, fromLayout: previousLayout)
            }
        }

        if !animated {
            pageDelegate?.collectionView?(self, didChangeToLayout: layout, fromLayout: previousLayout)
        }
    }

    public override func startInteractiveTransition(to layout: UICollectionViewLayout,
                                                    completion: UICollectionView.LayoutInteractiveTransitionCompletion? = nil)
                                                    -> UICollectionViewTransitionLayout {
        let transitionLayout = super.startInteractiveTransition(to: layout, completion: completion)
        activeTransitionLayout = transitionLayout
        return transitionLayout
    }

    public override func cancelInteractiveTransition() {
        super.cancelInteractiveTransition()

        guard let activeTransitionLayout = activeTransitionLayout else { assertionFailure(); return }
        pageDelegate?.collectionView?(self, didFinalizeTransitionLayout: activeTransitionLayout)
        self.activeTransitionLayout = nil
    }

    public override func finishInteractiveTransition() {
        super.finishInteractiveTransition()

        guard let activeTransitionLayout = activeTransitionLayout else { assertionFailure(); return }
        pageDelegate?.collectionView?(self, didFinalizeTransitionLayout: activeTransitionLayout)
        self.activeTransitionLayout = nil
    }

    // MARK: - Public API

    public func closestIndexPath(for point: CGPoint) -> IndexPath? {
        var closest: UICollectionViewCell?

        for cell in visibleCells {
            if cell.point(inside: convert(point, to: cell), with: nil) {
                return indexPath(for: cell)
            }
            if let soFar = closest {
                let dist1 = soFar.center.sqDistance(to: point)
                let dist2 = cell.center.sqDistance(to: point)

                if dist2 < dist1 {
                    closest = cell
                }
            } else {
                closest = cell
            }
        }

        if let closest = closest {
            return indexPath(for: closest)
        }
        return nil
    }
}
