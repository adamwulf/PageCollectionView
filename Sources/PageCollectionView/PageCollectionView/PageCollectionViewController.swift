//
//  PageCollectionViewController.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/23/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

open class PageCollectionViewController: UICollectionViewController, PageCollectionViewDelegate, UICollectionViewDelegatePageLayout {

    static let MinGestureScale: CGFloat = 1.0
    static let MaxGestureScale: CGFloat = 4.0

    enum ScalingDirection {
        case none
        case toPage
        case toGrid
    }

    public var _pageScale: CGFloat = 0
    private var maxPageScale: CGFloat = 300
    private var targetIndexPath: IndexPath?
    private var collapseGridIcon = GridIconView()
    private var collapseVerticalPageIcon = VerticalPageIconView()
    private var collapseHorizontalPageIcon = HorizontalPageIconView()
    private var zoomPercentOffset: CGPoint
    private var isZoomingPage: ScalingDirection
    private var pinchGesture: PinchVelocityGestureRecognizer

    open var pageScale: CGFloat {
        var scale = _pageScale
        if isZoomingPage == .toPage {
            scale = min(max(1.0, scale * pinchGesture.scale), maxPageScale)
        }
        return scale
    }

    open var pageCollectionView: PageCollectionView {
        return collectionView as! PageCollectionView
    }

    // MARK: - Init

    public init() {
        zoomPercentOffset = .zero
        isZoomingPage = .none
        pinchGesture = PinchVelocityGestureRecognizer()
        super.init(collectionViewLayout: ShelfLayout())
        pinchGesture.addTarget(self, action: #selector(didPinch))
    }

    public required init?(coder: NSCoder) {
        zoomPercentOffset = .zero
        isZoomingPage = .none
        pinchGesture = PinchVelocityGestureRecognizer()
        super.init(coder: coder)
        pinchGesture.addTarget(self, action: #selector(didPinch))
    }

    // MARK: - UIViewController

    open override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .lightGray
        collectionView.register(PageCollectionCell.self, forCellWithReuseIdentifier: String(describing: PageCollectionCell.self))
        collectionView.register(PageCollectionHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: String(describing: PageCollectionHeader.self))
        collectionView.reloadData()

        collectionView.addGestureRecognizer(pinchGesture)

        collapseGridIcon = GridIconView(frame: .zero)
        collapseGridIcon.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(collapseGridIcon)

        collapseGridIcon.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        collapseGridIcon.widthAnchor.constraint(equalToConstant: 100).isActive = true
        collapseGridIcon.heightAnchor.constraint(equalToConstant: 100).isActive = true
        collapseGridIcon.bottomAnchor.constraint(equalTo: collectionView.topAnchor, constant: -25).isActive = true

        collapseVerticalPageIcon = VerticalPageIconView(frame: .zero)
        collapseVerticalPageIcon.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(collapseVerticalPageIcon)

        collapseVerticalPageIcon.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        collapseVerticalPageIcon.widthAnchor.constraint(equalToConstant: 100).isActive = true
        collapseVerticalPageIcon.heightAnchor.constraint(equalToConstant: 60).isActive = true
        collapseVerticalPageIcon.bottomAnchor.constraint(equalTo: collectionView.topAnchor, constant: -25).isActive = true

        collapseHorizontalPageIcon = HorizontalPageIconView(frame: .zero)
        collapseHorizontalPageIcon.translatesAutoresizingMaskIntoConstraints = false
        collectionView.addSubview(collapseHorizontalPageIcon)

        collapseHorizontalPageIcon.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
        collapseHorizontalPageIcon.widthAnchor.constraint(equalToConstant: 100).isActive = true
        collapseHorizontalPageIcon.heightAnchor.constraint(equalToConstant: 60).isActive = true
        collapseHorizontalPageIcon.rightAnchor.constraint(equalTo: collectionView.leftAnchor, constant: -25).isActive = true

        collapseGridIcon.alpha = 0
        collapseVerticalPageIcon.alpha = 0
        collapseHorizontalPageIcon.alpha = 0

        _pageScale = 1.0

        collectionView.addObserver(self, forKeyPath: "collectionViewLayout", options: .old, context: nil)
        collectionView.alwaysBounceVertical = pageCollectionView.currentLayout?.bounceVertical ?? false
        collectionView.alwaysBounceHorizontal = pageCollectionView.currentLayout?.bounceHorizontal ?? false
    }

    // MARK: - UIViewController

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    // MARK: - Layout Helpers

    public var isDisplayingShelf: Bool {
        return pageCollectionView.currentLayout?.isMember(of: ShelfLayout.self) ?? false
    }

    public var isDisplayingGrid: Bool {
        return pageCollectionView.currentLayout?.isMember(of: GridLayout.self) ?? false
    }

    public var isDisplayingPage: Bool {
        return pageCollectionView.currentLayout?.isMember(of: PageLayout.self) ?? false
    }

    // MARK: - Gestures

    @objc private func reenablePinchGesture() {
        pinchGesture.isEnabled = true
    }

    private func brieflyDisablePinchGesture() {
        pinchGesture.isEnabled = false
        self.perform(#selector(reenablePinchGesture), with: nil, afterDelay: 0.5)
    }

    @objc private func didPinch(_ gesture: PinchVelocityGestureRecognizer) {
        if isDisplayingShelf {
            pinchFromShelf(gesture)
        } else if isDisplayingGrid {
            pinchFromGrid(gesture)
        } else if isDisplayingPage {
            pinchFromPage(gesture)
        }
    }

    private func pinchFromShelf(_ gesture: PinchVelocityGestureRecognizer) {
        let isActiveTransition = pageCollectionView.collectionViewLayout is UICollectionViewTransitionLayout
        let transitionLayout = pageCollectionView.activeTransitionLayout

        if !isActiveTransition && transitionLayout == nil && gesture.state == .began {
            let targetIndexPath = pageCollectionView.closestIndexPath(for: gesture.location(in: collectionView))
            let pageGridLayout = newGridLayout(for: targetIndexPath?.section ?? 0)
            pageGridLayout.targetIndexPath = targetIndexPath

            if targetIndexPath != nil {
                collectionView.startInteractiveTransition(to: pageGridLayout) { _, _ in
                    self.targetIndexPath = nil
                }
            }
        } else if let transitionLayout = transitionLayout, gesture.state == .changed {
            // 1 if we've completed the transition to the new layout, 0 if we are at the existing layout
            var progress: CGFloat = 0

            if pinchGesture.scale > 1 {
                // when pinching to zoom into a document from the shelf, the gesture scale
                // starts at 1 and increases with the zoom. Below, we clamp the pinch
                //  from 1x -> 4x and divide that by 3.0 to get a smooth transition from
                // 1x -> 3x maps to  0 -> 1
                progress = pinchGesture.scale.clamp(minFrom: Self.MinGestureScale, maxFrom: Self.MaxGestureScale, minTo: 0, maxTo: 1)
            } else {
                progress = 0
            }

            transitionLayout.transitionProgress = progress
            transitionLayout.invalidateLayout()
        } else if transitionLayout != nil && gesture.state == .ended {
            if pinchGesture.scaleDirection > 0 {
                collectionView.finishInteractiveTransition()
            } else {
                collectionView.cancelInteractiveTransition()
            }
        } else if transitionLayout != nil {
            collectionView.cancelInteractiveTransition()
        }
    }

    private func pinchFromGrid(_ gesture: PinchVelocityGestureRecognizer) {
        let isActiveTransition = pageCollectionView.collectionViewLayout is UICollectionViewTransitionLayout
        let transitionLayout = pageCollectionView.activeTransitionLayout

        if gesture.state == .began {
            targetIndexPath = pageCollectionView.closestIndexPath(for: gesture.location(in: collectionView))
        } else if let targetIndexPath = targetIndexPath, gesture.state == .changed {
            if let transitionLayout = transitionLayout {
                let toPage = transitionLayout.nextLayout.isKind(of: PageLayout.self)
                var progress: CGFloat = 0

                if toPage {
                    if gesture.scale > 1 {
                        progress = gesture.scale.clamp(minFrom: Self.MinGestureScale, maxFrom: Self.MaxGestureScale, minTo: 0, maxTo: 1)
                    } else {
                        progress = 0
                    }
                } else {
                    if gesture.scale < 1 {
                        progress = max(0, min(1, 1 - abs(gesture.scale)))
                    } else {
                        progress = 0
                    }
                }

                transitionLayout.transitionProgress = progress
                transitionLayout.invalidateLayout()
            } else if !isActiveTransition {
                guard let currentGridLayout = pageCollectionView.currentLayout as? GridLayout else { assertionFailure(); return }
                let nextLayout: UICollectionViewLayout
                if pinchGesture.scaleDirection > 0 {
                    // transition into page view
                    let pageLayout = newPageLayout(for: currentGridLayout.section)
                    pageLayout.targetIndexPath = targetIndexPath
                    nextLayout = pageLayout
                } else {
                    // transition into shelf
                    let shelfLayout = newShelfLayout()
                    shelfLayout.targetIndexPath = IndexPath(row: 0, section: currentGridLayout.section)
                    nextLayout = shelfLayout
                }

                collectionView.startInteractiveTransition(to: nextLayout) { _, _ in
                    self.targetIndexPath = nil
                }
            }
        } else if let transitionLayout = transitionLayout, gesture.state == .ended {
            let toPage = transitionLayout.nextLayout.isKind(of: PageLayout.self)

            if toPage && pinchGesture.scaleDirection > 0 {
                collectionView.finishInteractiveTransition()
            } else if !toPage && pinchGesture.scaleDirection < 0 {
                collectionView.finishInteractiveTransition()
            } else {
                collectionView.cancelInteractiveTransition()
            }
        } else if transitionLayout != nil {
            collectionView.cancelInteractiveTransition()
        }
    }

    private func pinchFromPage(_ gesture: PinchVelocityGestureRecognizer) {
        let isActiveTransition = pageCollectionView.collectionViewLayout is UICollectionViewTransitionLayout
        let transitionLayout = pageCollectionView.activeTransitionLayout
        var locInView = pinchGesture.location(in: collectionView.superview)
        locInView.x -= collectionView.frame.minX
        locInView.y -= collectionView.frame.minY

        if gesture.state == .began {
            let gestureLocInContent = gesture.location(in: collectionView)
            targetIndexPath = pageCollectionView.closestIndexPath(for: gestureLocInContent)
            zoomPercentOffset.x = gestureLocInContent.x / collectionView.contentSize.width
            zoomPercentOffset.y = gestureLocInContent.y / collectionView.contentSize.height

            if targetIndexPath == nil {
                // cancel if we can't find a target index
                pinchGesture.isEnabled = false
                pinchGesture.isEnabled = true
            }
        } else if gesture.state == .changed {
            if let transitionLayout = transitionLayout {
                let toPage = transitionLayout.nextLayout.isKind(of: PageLayout.self)
                let progress: CGFloat

                if toPage {
                    if gesture.scale > 1 {
                        progress = pinchGesture.scale.clamp(minFrom: Self.MinGestureScale, maxFrom: Self.MaxGestureScale, minTo: 0, maxTo: 1)
                    } else {
                        progress = 0
                    }
                } else {
                    if gesture.scale < 1 {
                        progress = max(0, min(1, 1 - abs(gesture.scale)))
                    } else {
                        progress = 0
                    }
                }

                transitionLayout.transitionProgress = progress
                transitionLayout.invalidateLayout()
            } else {
                if (isZoomingPage == .none && gesture.scaleDirection > 0) || isZoomingPage == .toPage || pageScale > 1 {
                    // scale page up
                    isZoomingPage = .toPage

                    // when zooming, to get a clean zoom animation we need to
                    // reset the entire layout, as this will trigger targetContentOffsetForProposedContentOffset:
                    // so that our layout + offset change will happen at the exact same time.
                    // this prevents the offset from jumping around during the gesture, and also
                    // prevents us invalidating the layout when setting the offset manually.
                    let layout = PageLayout(section: targetIndexPath?.section ?? 0)
                    // which page is being held
                    layout.targetIndexPath = targetIndexPath
                    // what % in both direction its held
                    layout.startingPercentOffset = zoomPercentOffset
                    // where the gesture is in collection view coordiates
                    layout.gestureRecognizer = pinchGesture
                    if let pageLayout = collectionView.collectionViewLayout as? PageLayout {
                        layout.fitWidth = pageLayout.fitWidth
                        layout.direction = pageLayout.direction
                    }

                    pageCollectionView.currentLayout?.targetIndexPath = targetIndexPath
                    (pageCollectionView.currentLayout as? PageLayout)?.startingPercentOffset = zoomPercentOffset
                    (pageCollectionView.currentLayout as? PageLayout)?.gestureRecognizer = pinchGesture

                    // Can't call [invalidateLayout] here, as this won't cause the collectionView to
                    // ask for targetContentOffsetForProposedContentOffset:. This means the contentOffset
                    // will remain exactly in place as the content scales. Setting a layout will
                    // ask for a targetContentOffset, so we can keep the page in view while we scale.
                    collectionView.setCollectionViewLayout(layout, animated: false)
                } else if !isActiveTransition && (isZoomingPage == .none || isZoomingPage == .toGrid) {
                    isZoomingPage = .toGrid
                    // transition into grid
                    let gridLayout = newGridLayout(for: targetIndexPath?.section ?? 0)
                    gridLayout.targetIndexPath = targetIndexPath

                    collectionView.startInteractiveTransition(to: gridLayout) { _, _ in
                        self.targetIndexPath = nil
                    }
                }
            }
        } else if gesture.state == .ended {
            if transitionLayout != nil {
                if gesture.scaleDirection < 0 {
                    collectionView.finishInteractiveTransition()
                } else {
                    collectionView.cancelInteractiveTransition()
                }
            }
            if isZoomingPage == .toPage {
                _pageScale = min(max(1.0, pageScale * pinchGesture.scale), maxPageScale)
            }
            isZoomingPage = .none
            (pageCollectionView.currentLayout as? PageLayout)?.startingPercentOffset = .zero
            (pageCollectionView.currentLayout as? PageLayout)?.gestureRecognizer = nil
        } else {
            if transitionLayout != nil {
                collectionView.cancelInteractiveTransition()
            } else {
                pageCollectionView.currentLayout?.invalidateLayout()
            }

            isZoomingPage = .none
            (pageCollectionView.currentLayout as? PageLayout)?.startingPercentOffset = .zero
            (pageCollectionView.currentLayout as? PageLayout)?.gestureRecognizer = nil
        }
    }

    // MARK: - UICollectionViewDataSource

    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        fatalError("AbstractMethodException")
    }

    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fatalError("AbstractMethodException")
    }

    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PageCollectionCell.self),
                                                      for: indexPath) as! PageCollectionCell

        cell.setup()
        cell.textLabel.text = "\(indexPath.section),\(indexPath.row)"
        cell.backgroundColor = .white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1

        return cell
    }

    open override func collectionView(_ collectionView: UICollectionView,
                                      viewForSupplementaryElementOfKind kind: String,
                                      at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                         withReuseIdentifier: String(describing: PageCollectionHeader.self),
                                                                         for: indexPath) as! PageCollectionHeader
            header.indexPath = indexPath

            return header
        } else {
            fatalError("Invalid supplementary view")
        }
    }

    // MARK: - UIScrollViewDelegate

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let kmin: CGFloat = 70
        let kdist: CGFloat = 40
        var vProgress: CGFloat = min(-kmin, max(-(kmin + kdist), scrollView.contentOffset.y))
        vProgress = abs(kmin + vProgress) / kdist

        var hProgress = min(-kmin, max(-(kmin + kdist), scrollView.contentOffset.x))
        hProgress = abs(kmin + hProgress) / kdist

        if isDisplayingGrid {
            collapseGridIcon.progress = vProgress
            collapseVerticalPageIcon.progress = 0
            collapseHorizontalPageIcon.progress = 0
        } else if isDisplayingPage && (pageCollectionView.currentLayout as? PageLayout)?.direction == .vertical {
            collapseGridIcon.progress = 0
            collapseVerticalPageIcon.progress = vProgress
            collapseHorizontalPageIcon.progress = 0
        } else if isDisplayingPage && (pageCollectionView.currentLayout as? PageLayout)?.direction == .horizontal {
            collapseGridIcon.progress = 0
            collapseVerticalPageIcon.progress = 0
            collapseHorizontalPageIcon.progress = hProgress
        } else {
            collapseGridIcon.progress = 0
            collapseVerticalPageIcon.progress = 0
            collapseHorizontalPageIcon.progress = 0
        }
    }

    open override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let isVerticalPage = isDisplayingPage && (pageCollectionView.currentLayout as? PageLayout)?.direction == .vertical
        let isHorizontalPage = isDisplayingPage && (pageCollectionView.currentLayout as? PageLayout)?.direction == .horizontal
        let verticalSuccess = scrollView.contentOffset.y < -100
        let horizontalSuccess = scrollView.contentOffset.x < -100

        if (verticalSuccess && (isDisplayingGrid || isVerticalPage)) || (horizontalSuccess && isHorizontalPage) {
            // turn off bounce during this animation, as the bounce from the scrollview
            // being overscrolled conflicts with the layout animation
            let nextLayout: ShelfLayout

            if isDisplayingGrid {
                nextLayout = newShelfLayout()
                nextLayout.targetIndexPath = IndexPath(row: 0, section: (pageCollectionView.currentLayout as? GridLayout)?.section ?? 0)
            } else if isDisplayingPage {
                nextLayout = newGridLayout(for: (pageCollectionView.currentLayout as? PageLayout)?.section ?? 0)
            } else {
                assertionFailure()
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.collectionView.setCollectionViewLayout(nextLayout, animated: true)
            }
        }
    }

    // MARK: - CollectionView

    open override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var updatedLayout: GridLayout?

        if isDisplayingShelf {
            updatedLayout = newGridLayout(for: indexPath.section)
        } else if isDisplayingGrid && pageCollectionView.activeTransitionLayout == nil {
            updatedLayout = newPageLayout(for: indexPath.section)
            updatedLayout?.targetIndexPath = indexPath
        }

        if let updatedLayout = updatedLayout {
            collectionView.setCollectionViewLayout(updatedLayout, animated: true, completion: nil)
        }
    }

    // MARK: - Shelf and Page Layout

    open func collectionView(_ collectionView: UICollectionView, layout: ShelfLayout, objectAtIndexPath: IndexPath) -> ShelfLayoutObject {
        fatalError("AbstractMethodException")
    }

    open func collectionView(_ collectionView: UICollectionView, layout: PageLayout, zoomScaleForIndexPath indexPath: IndexPath) -> CGFloat {
        return pageScale
    }

    // MARK: - Layout Changes

    open func collectionView(_ collectionView: PageCollectionView,
                             willChangeToLayout newLayout: UICollectionViewLayout,
                             fromLayout oldLayout: UICollectionViewLayout) {
        if newLayout.isMember(of: GridLayout.self) {
            collapseGridIcon.alpha = 1
            collapseVerticalPageIcon.alpha = 0
            collapseHorizontalPageIcon.alpha = 0
        } else if let pageLayout = newLayout as? PageLayout,
                  pageLayout.direction == .vertical {
            collapseGridIcon.alpha = 0
            collapseVerticalPageIcon.alpha = 1
            collapseHorizontalPageIcon.alpha = 0
        } else if let pageLayout = newLayout as? PageLayout,
                  pageLayout.direction == .horizontal {
            collapseGridIcon.alpha = 0
            collapseVerticalPageIcon.alpha = 0
            collapseHorizontalPageIcon.alpha = 1
        } else {
            collapseGridIcon.alpha = 0
            collapseVerticalPageIcon.alpha = 0
            collapseHorizontalPageIcon.alpha = 0
        }
    }

    open func collectionView(_ collectionView: PageCollectionView, didChangeToLayout newLayout: UICollectionViewLayout, fromLayout oldLayout: UICollectionViewLayout) {
        if let shelfLayout = newLayout as? ShelfLayout {
            shelfLayout.targetIndexPath = nil
            collectionView.alwaysBounceVertical = shelfLayout.bounceVertical
            collectionView.alwaysBounceHorizontal = shelfLayout.bounceHorizontal
        }
    }

    open func collectionView(_ collectionView: PageCollectionView, didFinalizeTransitionLayout transitionLayout: UICollectionViewTransitionLayout) {
        // Disable pinching during a transition animation. This delegate method is called for any
        // finishInteractiveTransition or cancelInteractiveTransition. This lets us turn off the
        // pinch gesture for a small time while the animation completes, then it will re-enable.
        brieflyDisablePinchGesture()
    }

    open override func observeValue(forKeyPath keyPath: String?,
                                    of object: Any?,
                                    change: [NSKeyValueChangeKey: Any]?,
                                    context: UnsafeMutableRawPointer?) {
        if let oldLayout = change?[.oldKey] as? UICollectionViewLayout {
            collectionView(pageCollectionView, willChangeToLayout: collectionView.collectionViewLayout, fromLayout: oldLayout)
        }
    }

    // MARK: - Subclasses

    open func newShelfLayout() -> ShelfLayout {
        return ShelfLayout()
    }

    open func newGridLayout(for section: Int) -> GridLayout {
        return GridLayout(section: section)
    }

    open func newPageLayout(for section: Int) -> PageLayout {
        return PageLayout(section: section)
    }
}
