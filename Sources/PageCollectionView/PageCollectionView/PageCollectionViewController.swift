//
//  PageCollectionViewController.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/23/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

class PageCollectionViewController: UICollectionViewController, PageCollectionViewDelegate {

    static let MinGestureScale: CGFloat = 1.0
    static let MaxGestureScale: CGFloat = 4.0

    enum ScalingDirection {
        case none
        case toPage
        case toGrid
    }

    private var _pageScale: CGFloat = 0
    private var maxPageScale: CGFloat = 300
    private var targetIndexPath: IndexPath?
    private var collapseGridIcon = GridIconView()
    private var collapseVerticalPageIcon = VerticalPageIconView()
    private var collapseHorizontalPageIcon = HorizontalPageIconView()
    private var zoomPercentOffset: CGPoint
    private var isZoomingPage: ScalingDirection
    private var pinchGesture: PinchVelocityGestureRecognizer

    var pageScale: CGFloat {
        var scale = _pageScale
        if isZoomingPage == .toPage {
            scale = min(max(1.0, scale * pinchGesture.scale), maxPageScale)
        }
        return scale
    }

    var pageCollectionView: PageCollectionView {
        return collectionView as! PageCollectionView
    }

    // MARK: - Init

    init() {
        zoomPercentOffset = .zero
        isZoomingPage = .none
        pinchGesture = PinchVelocityGestureRecognizer()
        super.init(collectionViewLayout: ShelfLayout())
        pinchGesture.addTarget(self, action: #selector(didPinch))
    }

    required init?(coder: NSCoder) {
        zoomPercentOffset = .zero
        isZoomingPage = .none
        pinchGesture = PinchVelocityGestureRecognizer()
        super.init(coder: coder)
        pinchGesture.addTarget(self, action: #selector(didPinch))
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .lightGray
        collectionView.register(PageCollectionCell.self, forCellWithReuseIdentifier: String(describing: PageCollectionCell.self))
        collectionView.register(PageCollectionHeader.self, forCellWithReuseIdentifier: String(describing: PageCollectionHeader.self))
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }, completion: nil)
    }

    // MARK: - Layout Helpers

    var isDisplayingShelf: Bool {
        return pageCollectionView.currentLayout?.isMember(of: ShelfLayout.self) ?? false
    }

    var isDisplayingGrid: Bool {
        return pageCollectionView.currentLayout?.isMember(of: GridLayout.self) ?? false
    }

    var isDisplayingPage: Bool {
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

    @objc func didPinch(_ gesture: PinchVelocityGestureRecognizer) {
        if isDisplayingShelf {
            pinchFromShelf(gesture)
        } else if isDisplayingGrid {
            pinchFromGrid(gesture)
        } else if isDisplayingPage {
            pinchFromPage(gesture)
        }
    }

    private func pinchFromShelf(_ gesture: PinchVelocityGestureRecognizer) {
        let transitionLayout = pageCollectionView.activeTransitionLayout

        if transitionLayout == nil && gesture.state == .began {
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
            } else {
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

    }

    // MARK: - Subclasses

    func newShelfLayout() -> ShelfLayout {
        return ShelfLayout()
    }

    func newGridLayout(for section: Int) -> GridLayout {
        return GridLayout(section: section)
    }

    func newPageLayout(for section: Int) -> PageLayout {
        return PageLayout(section: section)
    }
}
