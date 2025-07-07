//
//  SurveyChoiceCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import UIKit

class SurveyChoiceCell: UITableViewCell {
    let buttonImageView: UIImageView
    let choiceLabel: RichTextLabel
    let imageFontMetrics: UIFontMetrics
    var imageHeightConstraint = NSLayoutConstraint()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.buttonImageView = UIImageView(frame: .zero)
        self.choiceLabel = RichTextLabel(frame: .zero)

        self.imageFontMetrics = UIFontMetrics(forTextStyle: .title1)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        self.buttonImageView.isHighlighted = selected
        if self.isSelected {
            self.buttonImageView.tintColor = .apptentiveImageSelected
            self.accessibilityTraits.insert(UIAccessibilityTraits.selected)
        } else {
            self.buttonImageView.tintColor = .apptentiveImageNotSelected
            self.accessibilityTraits.remove(UIAccessibilityTraits.selected)
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.buttonImageView.isHighlighted = highlighted || self.isSelected
    }

    func configureViews() {
        self.contentView.backgroundColor = .apptentiveSecondaryGroupedBackground
        self.accessibilityTraits = .button

        self.buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        self.buttonImageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        self.buttonImageView.preferredSymbolConfiguration = .init(textStyle: .body, scale: .large)
        self.buttonImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.buttonImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        self.buttonImageView.contentMode = .scaleAspectFill
        self.contentView.addSubview(self.buttonImageView)

        self.choiceLabel.translatesAutoresizingMaskIntoConstraints = false
        self.choiceLabel.textStyle = .body
        self.choiceLabel.font = .apptentiveChoiceLabel
        self.choiceLabel.textColor = .apptentiveChoiceLabel
        self.choiceLabel.numberOfLines = 0
        self.choiceLabel.lineBreakMode = .byWordWrapping
        self.contentView.addSubview(self.choiceLabel)

        let imageCenteringConstraint = self.buttonImageView.centerXAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 32)
        imageCenteringConstraint.priority = .defaultHigh

        let textIndentingConstraint = self.choiceLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 60)
        textIndentingConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            self.choiceLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.choiceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.contentView.leadingAnchor, constant: 60),
            textIndentingConstraint,
            self.contentView.trailingAnchor.constraint(greaterThanOrEqualTo: self.choiceLabel.trailingAnchor, constant: 20),
            self.contentView.bottomAnchor.constraint(greaterThanOrEqualTo: self.choiceLabel.bottomAnchor, constant: 12),

            self.buttonImageView.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.contentView.leadingAnchor, multiplier: 1),
            self.buttonImageView.firstBaselineAnchor.constraint(equalTo: self.choiceLabel.firstBaselineAnchor),
            imageCenteringConstraint,

            self.choiceLabel.leadingAnchor.constraint(greaterThanOrEqualToSystemSpacingAfter: self.buttonImageView.trailingAnchor, multiplier: 1),
        ])
    }
}
