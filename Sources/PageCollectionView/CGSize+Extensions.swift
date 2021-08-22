//
//  File.swift
//  
//
//  Created by Adam Wulf on 8/22/21.
//

import UIKit

extension CGSize {
    func boundingSize(for rotation: CGFloat) -> CGSize {
        var bounds = CGRect(origin: .zero, size: self)
        bounds = bounds.applying(CGAffineTransform(rotationAngle: rotation))
        return bounds.size
    }
}
