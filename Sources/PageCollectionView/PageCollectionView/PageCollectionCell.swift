//
//  File.swift
//  
//
//  Created by Adam Wulf on 9/5/21.
//

import UIKit

class PageCollectionCell: UICollectionViewCell {
    let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public func setup() {
        guard textLabel.superview == nil else { return }
        textLabel.translatesAutoresizingMaskIntoConstraints = true
        textLabel.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        textLabel.textAlignment = .center
        contentView.addSubview(textLabel)
        textLabel.frame = contentView.bounds
        textLabel.text = "??"
    }
}
