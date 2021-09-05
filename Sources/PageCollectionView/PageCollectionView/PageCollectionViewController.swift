//
//  PageCollectionViewController.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/23/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

class PageCollectionViewController: UICollectionViewController, PageCollectionViewDelegate {

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

    }

    private func pinchFromGrid(_ gesture: PinchVelocityGestureRecognizer) {

    }

    private func pinchFromPage(_ gesture: PinchVelocityGestureRecognizer) {

    }
}
