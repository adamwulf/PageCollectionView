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
    }

    // MARK: - Gestures

    @objc func didPinch(_ gesture: PinchVelocityGestureRecognizer) {

    }

}
