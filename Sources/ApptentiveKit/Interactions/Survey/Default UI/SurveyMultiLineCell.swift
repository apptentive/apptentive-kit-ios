//
//  SurveyMultiLineCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyMultiLineCell: UITableViewCell {
    let textView: UITextView
    let placeholderLabel: UILabel
    var placeholderWidthConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?
    var leadingConstraint: NSLayoutConstraint?
    var trailingConstraint: NSLayoutConstraint?

    var tableViewStyle: UITableView.Style {
        didSet {
            self.borderLayer.borderWidth = 1.0 / self.traitCollection.displayScale
            self.borderLayer.cornerRadius = 6.0
            self.borderLayer.borderColor = UIColor.apptentiveTextInputBorder.cgColor

            switch self.tableViewStyle {
            case .insetGrouped:
                if #available(iOS 13.0, *) {
                    // The following determined experimentally to match UITextField
                    self.textView.textContainerInset = UIEdgeInsets(top: 1.0, left: -5.0, bottom: 1.0, right: -5.0)

                    self.leadingConstraint?.constant = 16.0
                    self.trailingConstraint?.constant = 16.0
                }

            default:
                // The following determined experimentally to match UITextField
                if #available(iOS 13.0, *) {
                    self.textView.textContainerInset = UIEdgeInsets(top: 6.0, left: 2.0, bottom: 6.0, right: 2.0)
                } else {
                    self.textView.textContainerInset = UIEdgeInsets(top: 4.0, left: 2.0, bottom: 4.0, right: 2.0)
                }

                self.leadingConstraint?.constant = 14.5
                self.trailingConstraint?.constant = 14.5
            }

            self.updatePlaceholderConstraints()
        }
    }

    var borderLayer: CALayer {
        if #available(iOS 13.0, *), case self.tableViewStyle = UITableView.Style.insetGrouped {
            return self.layer
        } else {
            return self.textView.layer
        }
    }

    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.textView.layer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.textView.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
            }
        }
    }

    private var placeholderLayoutConstraints = [NSLayoutConstraint]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textView = UITextView(frame: .zero)
        self.placeholderLabel = UILabel(frame: .zero)
        self.tableViewStyle = .grouped
        self.isMarkedAsInvalid = false
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .apptentiveSecondaryGroupedBackground
        self.contentView.addSubview(self.textView)

        self.configureTextView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTextView() {
        self.textView.backgroundColor = .apptentiveTextInputBackground
        self.textView.textColor = .apptentiveTextInput
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.adjustsFontForContentSizeCategory = true
        self.textView.font = .apptentiveTextInput.apptentiveRepairedFont()
        self.textView.returnKeyType = .default
        self.textView.tintColor = .apptentivetextInputTint

        self.leadingConstraint = self.textView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10.0)

        self.trailingConstraint = self.contentView.trailingAnchor.constraint(equalTo: self.textView.trailingAnchor, constant: 10.0)

        self.heightConstraint = self.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100.0)

        NSLayoutConstraint.activate(
            [
                self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 1.0),
                self.leadingConstraint, self.trailingConstraint,
                self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textView.bottomAnchor, multiplier: 1.0),
                self.heightConstraint,
            ].compactMap({ $0 }))

        self.textView.addSubview(self.placeholderLabel)
        self.placeholderLabel.isAccessibilityElement = false
        self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.placeholderLabel.adjustsFontForContentSizeCategory = true
        self.placeholderLabel.isUserInteractionEnabled = false
        self.placeholderLabel.adjustsFontSizeToFitWidth = true
        self.placeholderLabel.minimumScaleFactor = 0.1
        self.placeholderLabel.font = .apptentiveTextInputPlaceholder.apptentiveRepairedFont()
        self.placeholderLabel.textColor = .apptentiveTextInputPlaceholder

        self.updatePlaceholderConstraints()

        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: self.textView)
    }

    private func updatePlaceholderConstraints() {
        NSLayoutConstraint.deactivate(self.placeholderLayoutConstraints)

        // For some reason we need to constrain placeholder width as well as leading/trailing
        // to keep Dynamic Type from growing the label beyond where the trailing constraint
        // should be keeping it from growing. Below we manually calculate the width to set a constraint.
        let additionalPlaceholderInset: CGFloat = 5.0
        let placeholderWidthInset = self.textView.textContainerInset.right + self.textView.textContainerInset.left + additionalPlaceholderInset * 2

        self.placeholderLayoutConstraints = [
            self.placeholderLabel.topAnchor.constraint(equalTo: self.textView.topAnchor, constant: self.textView.textContainerInset.top),
            self.placeholderLabel.leadingAnchor.constraint(equalTo: self.textView.leadingAnchor, constant: self.textView.textContainerInset.left + additionalPlaceholderInset),
            self.textView.trailingAnchor.constraint(equalTo: self.placeholderLabel.trailingAnchor, constant: self.textView.textContainerInset.right + additionalPlaceholderInset),
            self.textView.widthAnchor.constraint(equalTo: self.placeholderLabel.widthAnchor, multiplier: 1, constant: placeholderWidthInset),
        ]

        NSLayoutConstraint.activate(self.placeholderLayoutConstraints)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func textViewDidChange() {
        self.placeholderLabel.isHidden = !self.textView.text.isEmpty
    }
}
