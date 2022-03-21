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
            self.textField.isAccessibilityElement = self.isExpanded
            self.textField.alpha = self.isExpanded ? 1 : 0
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
        self.textField.tintColor = .apptentiveSubmitButton

        // Set up additional border to display validation state
        self.textField.layer.borderWidth = 1.0 / self.traitCollection.displayScale
        self.textField.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
        self.textField.layer.cornerRadius = 6.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if self.skipLayoutAdjustment {
            self.skipLayoutAdjustment = false
            return
        }

        if let textLabel = self.textLabel, let imageView = self.imageView, let textLabelFrame = self.textLabelFrame, let imageViewFrame = self.imageViewFrame {

            if textLabelFrame != .zero {
                textLabel.frame = textLabelFrame
            }

            if imageViewFrame != .zero {
                imageView.frame = imageViewFrame
            }

            self.textField.frame = CGRect(
                x: textLabel.frame.minX - 7.5,
                y: textLabel.frame.maxY - 1,
                width: self.contentView.bounds.width - textLabel.frame.minX - 8.5,
                height: self.textField.intrinsicContentSize.height)
        }
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let additionalTextFieldHeight = self.textField.intrinsicContentSize.height * 1.5
        var fitSize = size

        if self.isExpanded {
            fitSize = CGSize(width: size.width, height: size.height - additionalTextFieldHeight)
        }

        let superSize = super.sizeThatFits(fitSize)

        self.textLabelFrame = self.textLabel?.frame
        self.imageViewFrame = self.imageView?.frame

        if self.isExpanded {
            return CGSize(width: superSize.width, height: superSize.height + additionalTextFieldHeight)
        } else {
            return superSize
        }
    }
}
