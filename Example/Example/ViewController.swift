//
//  ViewController.swift
//  Example
//
//  Created by Adam Wulf on 9/25/21.
//

import UIKit
import PageCollectionView

class ViewController: PageCollectionViewController, UICollectionViewDataSourceShelfLayout {

    var objects: [SampleObject] = []
    @IBOutlet var rotateButton: UIButton!
    @IBOutlet var bumpButton: UIButton!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var fitWidthButton: UIButton!
    @IBOutlet var directionButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.register(SimpleImageCell.self, forCellWithReuseIdentifier: String(describing: SimpleImageCell.self))

        var arr: [SampleObject] = []
        let fullWidth = self.collectionView.bounds.width

        for i in 0 ..< 100 {
            let obj = SampleObject()
            if i % 5 == 0 {
                obj.rotation = CGFloat.pi / 2
            }

            if i % 7 == 0 {
                obj.idealSize = CGSize(width: fullWidth / 2, height: 1.4 * fullWidth / 2)
            } else {
                // 8.5 x 11
                obj.idealSize = CGSize(width: 612, height: 792)
            }

            obj.physicalScale = 1.4
            arr.append(obj)
        }

        objects = arr
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        if let layout = collectionView.collectionViewLayout as? PageLayout {
            var center = collectionView.contentOffset
            center.x += collectionView.bounds.width / 2
            center.y += collectionView.bounds.height / 2

            let indexPath = pageCollectionView.closestIndexPath(for: center)

            layout.targetIndexPath = indexPath
            layout.invalidateLayout()

            coordinator.animate(alongsideTransition: nil, completion: { _ in
                layout.targetIndexPath = nil
            })
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 10
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return objects.count
    }

    // MARK: Actions

    @IBAction func rotate(_ sender: UIControl) {
        guard let currPageLayout = pageCollectionView.currentLayout as? PageLayout else { return }

        var center = collectionView.contentOffset
        center.x += collectionView.bounds.width / 2
        center.y += collectionView.bounds.height / 2

        guard let indexPath = pageCollectionView.closestIndexPath(for: center) else { return }
        let obj = objects[indexPath.row]

        obj.rotation = obj.rotation - (CGFloat.pi / 2)

        let layout = PageLayout(section: indexPath.section)
        layout.targetIndexPath = indexPath
        layout.direction = currPageLayout.direction
        layout.fitWidth = currPageLayout.fitWidth

        collectionView.setCollectionViewLayout(layout, animated: true)
    }

    @IBAction func bump(_ sender: UIControl) {
        guard let currPageLayout = pageCollectionView.currentLayout as? PageLayout else { return }

        var center = collectionView.contentOffset
        center.x += collectionView.bounds.width / 2
        center.y += collectionView.bounds.height / 2

        guard let indexPath = pageCollectionView.closestIndexPath(for: center) else { return }
        let obj = objects[indexPath.row]

        obj.rotation = obj.rotation - 0.1

        let layout = PageLayout(section: indexPath.section)
        layout.targetIndexPath = indexPath
        layout.direction = currPageLayout.direction
        layout.fitWidth = currPageLayout.fitWidth

        collectionView.setCollectionViewLayout(layout, animated: true)
    }

    @IBAction func reset(_ sender: UIControl) {
        guard let currPageLayout = pageCollectionView.currentLayout as? PageLayout else { return }

        var center = collectionView.contentOffset
        center.x += collectionView.bounds.width / 2
        center.y += collectionView.bounds.height / 2

        guard let indexPath = pageCollectionView.closestIndexPath(for: center) else { return }
        let obj = objects[indexPath.row]

        obj.rotation = 0

        let layout = PageLayout(section: indexPath.section)
        layout.targetIndexPath = indexPath
        layout.direction = currPageLayout.direction
        layout.fitWidth = currPageLayout.fitWidth

        collectionView.setCollectionViewLayout(layout, animated: true)
    }

    @IBAction func swapScale(_ sender: UIControl) {
        guard let currPageLayout = pageCollectionView.currentLayout as? PageLayout else { return }

        var center = collectionView.contentOffset
        center.x += collectionView.bounds.width / 2
        center.y += collectionView.bounds.height / 2

        guard let indexPath = pageCollectionView.closestIndexPath(for: center) else { return }
        let obj = objects[indexPath.row]

        obj.rotation = 0

        let layout = PageLayout(section: indexPath.section)
        layout.targetIndexPath = indexPath
        layout.direction = currPageLayout.direction
        layout.fitWidth = !currPageLayout.fitWidth

        // TODO: clean up target scale
        _pageScale = 1.0

        collectionView.setCollectionViewLayout(layout, animated: true)
    }

    @IBAction func toggleDirection(_ sender: UIControl) {
        guard let currPageLayout = pageCollectionView.currentLayout as? PageLayout else { return }

        var center = collectionView.contentOffset
        center.x += collectionView.bounds.width / 2
        center.y += collectionView.bounds.height / 2

        guard let indexPath = pageCollectionView.closestIndexPath(for: center) else { return }
        let obj = objects[indexPath.row]

        obj.rotation = 0

        let layout = PageLayout(section: indexPath.section)
        layout.targetIndexPath = indexPath
        if currPageLayout.direction == .vertical {
            layout.direction = .horizontal
        } else {
            layout.direction = .vertical
        }
        layout.fitWidth = !currPageLayout.fitWidth

        // TODO: clean up target scale
        _pageScale = 1.0

        collectionView.setCollectionViewLayout(layout, animated: true)
    }

    // MARK: CollectionView DataSource

    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: SimpleImageCell.self),
                                                      for: indexPath) as! SimpleImageCell

        cell.prepareForReuse()
        cell.imageView.image = UIImage(named: "pdf-page")

        return cell
    }

    // MARK: Shelf Layout

    override func collectionView(_ collectionView: UICollectionView,
                                 layout: ShelfLayout,
                                 objectAtIndexPath indexPath: IndexPath) -> ShelfLayoutObject {
        return objects[indexPath.row]
    }

    override func collectionView(_ collectionView: PageCollectionView,
                                 didChangeToLayout newLayout: UICollectionViewLayout,
                                 fromLayout oldLayout: UICollectionViewLayout) {
        super.collectionView(collectionView, didChangeToLayout: newLayout, fromLayout: oldLayout)

        let isPageView = newLayout as? PageLayout != nil

        rotateButton.isHidden = !isPageView
        bumpButton.isHidden = !isPageView
        resetButton.isHidden = !isPageView
        fitWidthButton.isHidden = !isPageView
        directionButton.isHidden = !isPageView
    }
}
