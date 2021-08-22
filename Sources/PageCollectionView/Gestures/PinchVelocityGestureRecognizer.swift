//
//  PinchVelocityGestureRecognizer.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

public class PinchVelocityGestureRecognizer: UIPinchGestureRecognizer {
    var scaleDirection: CGFloat = 0
    /// Adjustment tracks the distance that UIKit thinks the gesture has moved, vs what we'll output in our location
    var adjustment: CGPoint = .zero
    /// scaledAdjustment tracks the adjustment location, but multiplies each step by the current scale. useful for
    /// tracking adjustment with scaling content
    var scaledAdjustment: CGPoint = .zero

    private var lastScale: CGFloat = 0
    private var touches: Set<UITouch> = Set()
    private var adjustWait: CGPoint = .zero
    private static let LowPass: CGFloat = 0.8

    // MARK: - Public

    func oldLocation(in view: UIView) -> CGPoint {
        return super.location(in: view)
    }

    func firstLocation(in view: UIView) -> CGPoint {
        var loc = location(in: view)
        loc.x += adjustment.x
        loc.y += adjustment.y
        return loc
    }

    func scaledFirstLocation(in view: UIView) -> CGPoint {
        var loc = location(in: view)
        loc.x += scaledAdjustment.x * scale
        loc.y += scaledAdjustment.y * scale
        return loc
    }

    // MARK: UIPinchGestureRecognizer

    public override func location(in view: UIView?) -> CGPoint {
        var loc: CGPoint = .zero

        for touch in touches {
            let touchLoc = touch.location(in: view)
            loc.x += touchLoc.x
            loc.y += touchLoc.y
        }

        if touches.count > 0 {
            loc.x /= CGFloat(touches.count)
            loc.y /= CGFloat(touches.count)
        }

        loc.x += adjustWait.x
        loc.y += adjustWait.y

        return loc
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        let stateBefore = state
        let before = location(in: view)
        self.touches.formUnion(touches)

        super.touchesBegan(touches, with: event)
        let after = location(in: view)

        if self.touches.count > 1 && stateBefore == .changed {
            adjustment.x += adjustWait.x
            adjustment.y += adjustWait.y
            adjustment.x += (before.x - after.x)
            adjustment.y += (before.y - after.y)

            scaledAdjustment.x = adjustWait.x / scale
            scaledAdjustment.y = adjustWait.y / scale
            scaledAdjustment.x += (before.x - after.x) / scale
            scaledAdjustment.y += (before.y - after.y) / scale

            adjustWait = .zero
        }
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        lastScale = scale
        super.touchesMoved(touches, with: event)
        let updatedDirction = scale - lastScale
        scaleDirection = scaleDirection * Self.LowPass + updatedDirction * (1.0 - Self.LowPass)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        let before = location(in: view)

        self.touches.subtract(touches)

        super.touchesEnded(touches, with: event)

        let after = location(in: view)

        adjustWait.x += (before.x - after.x)
        adjustWait.y += (before.y - after.y)

        if self.touches.isEmpty {
            adjustment = .zero
            scaledAdjustment = .zero
            adjustWait = .zero
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        self.touches.subtract(touches)
        super.touchesCancelled(touches, with: event)

        if self.touches.isEmpty {
            adjustment = .zero
            scaledAdjustment = .zero
            adjustWait = .zero
        }
    }

    public override func ignore(_ touch: UITouch, for event: UIEvent) {
        let before = location(in: view)
        self.touches.remove(touch)
        super.ignore(touch, for: event)
        let after = location(in: view)

        adjustWait.x -= (before.x - after.x)
        adjustment.y -= (before.y - after.y)


        if self.touches.isEmpty {
            adjustment = .zero
            scaledAdjustment = .zero
            adjustWait = .zero
        }
    }
}
