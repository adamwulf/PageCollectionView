//
//  HostViewController.swift
//  Example
//
//  Created by Adam Wulf on 9/26/21.
//

import Foundation
import UIKit

class HostViewController: UINavigationController {

    override func viewDidLoad() {
        view.backgroundColor = .white

        let vc = topViewController as! ViewController

        view.addSubview(vc.resetButton)
        vc.resetButton.translatesAutoresizingMaskIntoConstraints = false
        vc.resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        vc.resetButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 100).isActive = true
        vc.resetButton.sizeToFit()

        view.addSubview(vc.bumpButton)
        vc.bumpButton.translatesAutoresizingMaskIntoConstraints = false
        vc.bumpButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        vc.bumpButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 150).isActive = true
        vc.bumpButton.sizeToFit()

        view.addSubview(vc.rotateButton)
        vc.rotateButton.translatesAutoresizingMaskIntoConstraints = false
        vc.rotateButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        vc.rotateButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 200).isActive = true
        vc.rotateButton.sizeToFit()

        view.addSubview(vc.fitWidthButton)
        vc.fitWidthButton.translatesAutoresizingMaskIntoConstraints = false
        vc.fitWidthButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        vc.fitWidthButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 250).isActive = true
        vc.fitWidthButton.sizeToFit()

        view.addSubview(vc.directionButton)
        vc.directionButton.translatesAutoresizingMaskIntoConstraints = false
        vc.directionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        vc.directionButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 300).isActive = true
        vc.directionButton.sizeToFit()
    }
}
