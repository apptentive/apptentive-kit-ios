//
//  PhotoCell.swift
//  Example
//
//  Created by Frank Schmitt on 6/24/21.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var heartButton: UIButton!

    override func awakeFromNib() {
        self.imageView.layer.cornerCurve = .continuous
    }
}
