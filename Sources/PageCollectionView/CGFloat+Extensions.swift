//
//  File.swift
//  
//
//  Created by Adam Wulf on 9/5/21.
//

import CoreGraphics

extension CGFloat {
    func clamp(minFrom: CGFloat, maxFrom: CGFloat, minTo: CGFloat, maxTo: CGFloat) -> CGFloat {
        return (((self - minFrom) / (maxFrom - minFrom)) * (maxTo - minTo) + minTo)
    }
}
