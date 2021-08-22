//
//  ShelfLayoutObject.swift
//  PageCollectionView
//
//  Created by Adam Wulf on 8/22/21.
//  Copyright © 2021 Milestone Made. All rights reserved.
//

import UIKit

protocol ShelfLayoutObject {
    var idealSize: CGSize { get }
    var physicalScale: CGFloat { get }
    var rotation: CGFloat { get }
}
