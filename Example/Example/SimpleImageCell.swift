//
//  SimpleImageCell.swift
//  Example
//
//  Created by Adam Wulf on 10/2/21.
//

import UIKit

class SimpleImageCell: UICollectionViewCell {

    let imageView = UIImageView()

    override func prepareForReuse() {
        if imageView.superview == nil {
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            contentView.addSubview(imageView)
            imageView.frame = contentView.bounds
        }
    }
}
