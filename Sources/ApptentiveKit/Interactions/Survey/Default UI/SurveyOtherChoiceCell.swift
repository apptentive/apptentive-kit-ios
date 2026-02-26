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

    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.textFieldBackgroundView.layer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.textFieldBackgroundView.layer.borderColor = UIColor.apptentiveOtherTextInputBorder.cgColor
            }
        }
    }

    var isExpanded = false {
        didSet {
            self.textField.isAccessibilityElement = self.isExpanded
            self.textField.alpha = self.isExpanded ? 1 : 0
            self.textFieldBackgroundView.alpha = self.isExpanded ? 1 : 0
            self.textFieldSpacerConstraint.isActive = self.isExpanded
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField(frame: .zero)

        self.isMarkedAsInvalid = false

        if #available(iOS 26, *) {
            self.textFieldBorderHorizontalPadding = 14
            self.textFieldHeight = 40
        } else {
            self.textFieldBorderHorizontalPadding = 7
            self.textFieldHeight = 32
        }

        self.fontMetrics = UIFontMetrics(forTextStyle: .body)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        if #available(iOS 17.0, *) {
            self.dynamicTypeObservation = registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
                self.handleDynamicTypeChange()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor
    deinit {
        if #available(iOS 17.0, *) {
            if let dynamicTypeObservation = self.dynamicTypeObservation as? UITraitChangeRegistration {
                unregisterForTraitChanges(dynamicTypeObservation)
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.handleDynamicTypeChange()
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

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.imageView?.isHighlighted = highlighted || self.isSelected
    }

    override func configureViews() {
        super.configureViews()

        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.insertSubview(self.textField, at: 0)

        self.textFieldBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.insertSubview(self.textFieldBackgroundView, belowSubview: self.textField)

        self.textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.textField.borderStyle = .none
        self.textField.accessibilityIdentifier = "OtherCell"
        self.textField.tintColor = .apptentivetextInputTint
        self.textField.font = .apptentiveTextInput
        self.textField.adjustsFontForContentSizeCategory = true
        self.textField.backgroundColor = .clear
        self.textField.textColor = .apptentiveTextInput
        self.textField.returnKeyType = .done

        if #available(iOS 26.0, *) {
            self.textFieldBackgroundView.cornerConfiguration = .capsule(maximumRadius: 26)
        } else {
            self.textFieldBackgroundView.layer.cornerRadius = 6.0
        }

        self.textFieldBackgroundView.layer.borderColor = UIColor.apptentiveOtherTextInputBorder.cgColor
        self.textFieldBackgroundView.backgroundColor = .apptentiveOtherTextInputBackground
        self.textFieldBackgroundView.layer.borderWidth = 1 / self.traitCollection.displayScale

        self.textFieldSpacerConstraint = self.textField.topAnchor.constraint(equalToSystemSpacingBelow: self.choiceLabel.bottomAnchor, multiplier: 1)
        self.textFieldHeightConstraint = self.textField.heightAnchor.constraint(equalToConstant: self.textFieldHeight)

        NSLayoutConstraint.activate([
            self.textField.leadingAnchor.constraint(equalTo: self.choiceLabel.leadingAnchor, constant: 0),
            self.contentView.trailingAnchor.constraint(equalTo: self.textField.trailingAnchor, constant: 20),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textField.bottomAnchor, multiplier: 1),
            self.textFieldHeightConstraint,
            self.textField.topAnchor.constraint(equalTo: self.textFieldBackgroundView.topAnchor, constant: 1),
            self.textField.leadingAnchor.constraint(equalTo: self.textFieldBackgroundView.leadingAnchor, constant: self.textFieldBorderHorizontalPadding),
            self.textFieldBackgroundView.trailingAnchor.constraint(equalTo: self.textField.trailingAnchor, constant: self.textFieldBorderHorizontalPadding),
            self.textFieldBackgroundView.bottomAnchor.constraint(equalTo: self.textField.bottomAnchor, constant: 1),
        ])

        self.isExpanded = false
    }

    // MARK: - Private

    private var textFieldSpacerConstraint = NSLayoutConstraint()
    private var textFieldHeightConstraint = NSLayoutConstraint()
    private var textFieldBackgroundView = UIView()
    private let textFieldBorderHorizontalPadding: CGFloat
    private let textFieldHeight: CGFloat
    private var dynamicTypeObservation: Any?
    private var fontMetrics: UIFontMetrics

    private func handleDynamicTypeChange() {
        self.textFieldHeightConstraint.constant = self.fontMetrics.scaledValue(for: self.textFieldHeight, compatibleWith: self.traitCollection)
    }
}
