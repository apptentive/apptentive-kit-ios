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
    var tableViewStyle: UITableView.Style {
        didSet {
            switch self.tableViewStyle {
            case .insetGrouped:
                if #available(iOS 13.0, *) {
                    self.layer.borderColor = UIColor.tertiaryLabel.cgColor
                    self.layer.borderWidth = 1.0
                    // The following determined experimentally to match UITextField
                    self.textView.textContainerInset = UIEdgeInsets(top: 1.0, left: -5.0, bottom: 1.0, right: -5.0)
                }
            default:
                self.textView.layer.borderColor = self.textFieldBorderColor.cgColor
                self.textView.layer.borderWidth = 1.0 / self.traitCollection.displayScale
                self.textView.layer.cornerRadius = 6.0

                // The following determined experimentally to match UITextField
                if #available(iOS 13.0, *) {
                    self.textView.textContainerInset = UIEdgeInsets(top: 6.0, left: 2.0, bottom: 6.0, right: 2.0)
                } else {
                    self.textView.textContainerInset = UIEdgeInsets(top: 4.0, left: 2.0, bottom: 4.0, right: 2.0)
                }
            }

            self.updatePlaceholderConstraints()
        }
    }
    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.textView.layer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.textView.layer.borderColor = self.textFieldBorderColor.cgColor
            }
        }
    }

    // Colors below determined experimentally to match UITextField
    private let textFieldBorderColor = UIColor(red: 180.0 / 255.0, green: 180.0 / 255.0, blue: 180.0 / 255.0, alpha: 0.75)
    private let placholderTextColor: UIColor = {
        if #available(iOS 13.0, *) {
            return .placeholderText
        } else {
            return .init(red: 0.235294, green: 0.235294, blue: 0.262745, alpha: 0.3)
        }
    }()

    private var placeholderLayoutConstraints = [NSLayoutConstraint]()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textView = UITextView(frame: .zero)
        self.placeholderLabel = UILabel(frame: .zero)
        self.tableViewStyle = .grouped
        self.isMarkedAsInvalid = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textView)

        self.configureTextView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTextView() {
        self.textView.backgroundColor = UIColor.textInputBackground
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.adjustsFontForContentSizeCategory = true
        self.textView.font = .preferredFont(forTextStyle: .body)
        self.textView.returnKeyType = .default
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 1.0),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textView.bottomAnchor, multiplier: 1.0),
            self.textView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.contentView.leadingAnchor, multiplier: 1.0),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textView.trailingAnchor, multiplier: 1.0),
        ])

        self.heightConstraint = self.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100.0)
        self.heightConstraint?.isActive = true

        self.textView.addSubview(self.placeholderLabel)

        self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.placeholderLabel.adjustsFontForContentSizeCategory = true
        self.placeholderLabel.isUserInteractionEnabled = false
        self.placeholderLabel.adjustsFontSizeToFitWidth = true
        self.placeholderLabel.minimumScaleFactor = 0.1
        self.placeholderLabel.font = .preferredFont(forTextStyle: .body)
        self.placeholderLabel.textColor = self.placholderTextColor

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
