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
    var skipLayoutAdjustment = true
    var textLabelFrame: CGRect?
    var imageViewFrame: CGRect?

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
        self.isMarkedAsInvalid = false
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .apptentiveSecondaryGroupedBackground
        self.textField.isHidden = false
        self.textField.alpha = 0.0
        self.contentView.addSubview(self.textField)
        self.setupViews()

        NotificationCenter.default.addObserver(forName: UIContentSizeCategory.didChangeNotification, object: nil, queue: .main) { [weak self] notification in
            self?.skipLayoutAdjustment = true
            self?.layoutSubviews()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.textLabelFrame = nil
        self.imageViewFrame = nil

        self.sizeToFit()
        self.skipLayoutAdjustment = true
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
            self.accessibilityTraits.insert(UIAccessibilityTraits.selected)
        } else {
            self.imageView?.tintColor = .apptentiveImageNotSelected
            self.accessibilityTraits.remove(UIAccessibilityTraits.selected)
        }
    }

    var isExpanded = false {
        didSet {
            if self.isExpanded {
                self.setExpandedConstraints()
                self.textField.alpha = 1
            } else {
                self.setCollapsedConstraints()
                self.textField.alpha = 0
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.imageView?.isHighlighted = highlighted || self.isSelected
    }

    private func setupViews() {
        self.textLabel?.numberOfLines = 0
        self.textLabel?.lineBreakMode = .byWordWrapping
        self.textLabel?.font = .apptentiveChoiceLabel
        self.textLabel?.textColor = .apptentiveChoiceLabel
        self.textLabel?.adjustsFontForContentSizeCategory = true

        self.textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.textField.borderStyle = .roundedRect
        self.textField.accessibilityIdentifier = "OtherCell"
        self.textField.tintColor = .apptentivetextInputTint

        // Set up additional border to display validation state
        self.textField.layer.borderWidth = 1.0 / self.traitCollection.displayScale
        self.textField.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
        self.textField.layer.cornerRadius = 6.0

        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.font = .apptentiveTextInput

        self.textField.adjustsFontForContentSizeCategory = true
        self.textField.backgroundColor = .apptentiveTextInputBackground
        self.textField.textColor = .apptentiveTextInput
        self.textField.returnKeyType = .done

        NSLayoutConstraint.activate([
            self.otherTextLabel.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 55.5),
            self.contentView.trailingAnchor.constraint(equalTo: self.otherTextLabel.trailingAnchor, constant: 20),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textField.trailingAnchor, multiplier: 2.0),
            self.otherTextLabel.leadingAnchor.constraint(equalTo: self.textField.leadingAnchor, constant: 7),

            self.otherTextLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 12),
            self.textField.topAnchor.constraint(greaterThanOrEqualTo: self.contentView.topAnchor, constant: 4.5),
            self.contentView.bottomAnchor.constraint(equalTo: self.textField.bottomAnchor, constant: 5.5),
        ])
    }

    private func setCollapsedConstraints() {
        self.contentViewBottomConstraint.isActive = true
        self.splitterConstraint.isActive = false
    }

    private func setExpandedConstraints() {
        self.contentViewBottomConstraint.isActive = false
        self.splitterConstraint.isActive = true
    }
}
