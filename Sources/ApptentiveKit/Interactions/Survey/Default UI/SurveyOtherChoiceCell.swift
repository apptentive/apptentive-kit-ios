//
//  SurveyOtherChoiceCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/16/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyOtherChoiceCell: SurveyChoiceCell {
    let textField: UITextField
    var textFieldSpacerConstraint = NSLayoutConstraint()

    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.textField.layer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.textField.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField(frame: .zero)

        self.isMarkedAsInvalid = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        self.imageView?.isHighlighted = selected
        if self.isSelected {
            self.imageView?.tintColor = .apptentiveImageSelected
            self.accessibilityTraits.insert(UIAccessibilityTraits.selected)
        } else {
            self.imageView?.tintColor = .apptentiveImageNotSelected
            self.accessibilityTraits.remove(UIAccessibilityTraits.selected)
        }
    }

    var isExpanded = false {
        didSet {
            self.textField.isAccessibilityElement = self.isExpanded
            self.textField.alpha = self.isExpanded ? 1 : 0
            self.textFieldSpacerConstraint.isActive = self.isExpanded
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.imageView?.isHighlighted = highlighted || self.isSelected
    }

    override func configureViews() {
        super.configureViews()

        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.insertSubview(self.textField, at: 0)

        self.textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.textField.borderStyle = .roundedRect
        self.textField.accessibilityIdentifier = "OtherCell"
        self.textField.tintColor = .apptentivetextInputTint
        self.textField.font = .apptentiveTextInput
        self.textField.adjustsFontForContentSizeCategory = true
        self.textField.backgroundColor = .apptentiveTextInputBackground
        self.textField.textColor = .apptentiveTextInput
        self.textField.returnKeyType = .done

        // Set up additional border to display validation state
        self.textField.layer.borderWidth = 1.0 / self.traitCollection.displayScale
        self.textField.layer.cornerRadius = 6.0

        self.textFieldSpacerConstraint = self.textField.topAnchor.constraint(equalToSystemSpacingBelow: self.choiceLabel.bottomAnchor, multiplier: 1)

        NSLayoutConstraint.activate([
            self.textField.leadingAnchor.constraint(equalTo: self.choiceLabel.leadingAnchor, constant: -7),
            self.contentView.trailingAnchor.constraint(equalTo: self.textField.trailingAnchor, constant: 20),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textField.bottomAnchor, multiplier: 1),
        ])

        self.isExpanded = false
    }
}
