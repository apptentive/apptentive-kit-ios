//
//  RangeChoiceCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 12/15/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyRangeCell: UITableViewCell {

    var choiceLabels: [String]? {
        didSet {
            setupViews()
        }
    }
    var segmentedControl: UISegmentedControl?
    let minLabel = UILabel()
    let maxLabel = UILabel()

    override func prepareForReuse() {
        super.prepareForReuse()
        self.segmentedControl?.removeFromSuperview()
    }

    private func setupViews() {
        self.configureSegmentedControl()
        self.configureMinMaxLabels()
    }

    private func configureSegmentedControl() {
        self.segmentedControl = UISegmentedControl(items: choiceLabels)

        if let segmentedControl = self.segmentedControl {
            self.contentView.addSubview(segmentedControl)
            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            segmentedControl.layer.borderColor = UIColor.apptentiveRangeControlBorder.cgColor
            segmentedControl.layer.borderWidth = 1

            NSLayoutConstraint.activate([
                segmentedControl.heightAnchor.constraint(equalToConstant: 44),
                segmentedControl.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 7),
                segmentedControl.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10),
                segmentedControl.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
            ])
        }
    }

    private func configureMinMaxLabels() {
        if let segmentedControl = self.segmentedControl {
            self.minLabel.textColor = .gray
            self.minLabel.font = .preferredFont(forTextStyle: .caption2)
            self.minLabel.numberOfLines = 0
            self.minLabel.lineBreakMode = .byWordWrapping
            self.minLabel.adjustsFontForContentSizeCategory = true
            self.minLabel.textAlignment = .left

            self.maxLabel.textColor = .gray
            self.maxLabel.font = .preferredFont(forTextStyle: .caption2)
            self.maxLabel.numberOfLines = 0
            self.maxLabel.lineBreakMode = .byWordWrapping
            self.maxLabel.adjustsFontForContentSizeCategory = true
            self.maxLabel.textAlignment = .right

            let stackView = UIStackView(arrangedSubviews: [self.minLabel, self.maxLabel])
            stackView.axis = .horizontal
            self.contentView.addSubview(stackView)
            stackView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                stackView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
                stackView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15),
                stackView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -15),
                self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: stackView.bottomAnchor, multiplier: 1.0),
            ])
        }
    }
}
