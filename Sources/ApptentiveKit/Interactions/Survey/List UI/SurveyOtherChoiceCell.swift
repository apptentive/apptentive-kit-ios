//
//  SurveyOtherChoiceCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/16/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyOtherChoiceCell: UITableViewCell {
    let textField: UITextField
    var otherTextLabel: UILabel
    var contentViewBottomConstraint, splitterConstraint: NSLayoutConstraint

    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.textField.layer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.textField.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField(frame: .zero)
        self.otherTextLabel = UILabel(frame: .zero)
        self.contentViewBottomConstraint = NSLayoutConstraint()
        self.splitterConstraint = NSLayoutConstraint()
        self.isMarkedAsInvalid = false
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .apptentiveSecondaryGroupedBackground
        self.contentViewBottomConstraint = self.contentView.bottomAnchor.constraint(greaterThanOrEqualTo: self.otherTextLabel.bottomAnchor, constant: 12)
        self.splitterConstraint = self.textField.topAnchor.constraint(equalTo: self.otherTextLabel.bottomAnchor, constant: 10)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.textField.isHidden = false
        self.textField.alpha = 0.0
        self.contentView.addSubview(self.textField)
        self.contentView.addSubview(self.otherTextLabel)
        self.setupViews()
    }

    func setMarkedAsInvalid(_ markedAsInvalid: Bool, animated: Bool) {
        let animationDuration = animated ? SurveyViewController.animationDuration : 0

        UIView.animate(withDuration: animationDuration) {
            self.isMarkedAsInvalid = markedAsInvalid
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        self.imageView?.isHighlighted = selected

        if self.isSelected {
            self.imageView?.tintColor = .apptentiveImageSelected
            self.setExpandedConstraints()

            UIView.animate(withDuration: SurveyViewController.animationDuration) {
                self.textField.alpha = 1
            }
        } else {
            self.imageView?.tintColor = .apptentiveImageNotSelected
            self.setCollapsedConstraints()

            UIView.animate(withDuration: SurveyViewController.animationDuration) {
                self.textField.alpha = 0
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.imageView?.isHighlighted = highlighted || self.isSelected
    }

    private func setupViews() {
        //otherTextLabel
        self.otherTextLabel.translatesAutoresizingMaskIntoConstraints = false
        self.otherTextLabel.numberOfLines = 0
        self.otherTextLabel.lineBreakMode = .byWordWrapping
        self.otherTextLabel.font = .apptentiveChoiceLabel
        self.otherTextLabel.textColor = .apptentiveChoiceLabel
        self.otherTextLabel.adjustsFontForContentSizeCategory = true

        //textField
        self.textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.borderStyle = .roundedRect
        self.textField.accessibilityIdentifier = "OtherCell"

        // Set up additional border to display validation state
        self.textField.layer.borderWidth = 1.0 / self.traitCollection.displayScale
        self.textField.layer.borderColor = UIColor.clear.cgColor
        self.textField.layer.cornerRadius = 6.0

        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.font = .apptentiveChoiceLabel
        self.textField.adjustsFontForContentSizeCategory = true
        self.textField.backgroundColor = .apptentiveTextInputBackground
        self.textField.textColor = .apptentiveChoiceLabel
        self.textField.returnKeyType = .done

        NSLayoutConstraint.activate([
            self.otherTextLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 55.5),
            self.otherTextLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -20),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textField.trailingAnchor, multiplier: 1.0),
            self.textField.leadingAnchor.constraint(equalTo: self.otherTextLabel.leadingAnchor, constant: -7),

            self.otherTextLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.textField.topAnchor.constraint(greaterThanOrEqualTo: self.contentView.topAnchor, constant: 4.5),
            self.contentView.bottomAnchor.constraint(equalTo: self.textField.bottomAnchor, constant: 5.5),
        ])
    }

    func setCollapsedConstraints() {
        self.contentViewBottomConstraint.isActive = true
        self.splitterConstraint.isActive = false
    }

    func setExpandedConstraints() {
        self.contentViewBottomConstraint.isActive = false
        self.splitterConstraint.isActive = true
    }
}
