//
//  SurveySingleLineCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveySingleLineCell: UITableViewCell {
    let textField: UITextField
    var tableViewStyle: UITableView.Style {
        didSet {
            self.borderLayer.borderWidth = 1.0 / self.traitCollection.displayScale
            self.borderLayer.cornerRadius = 6.0
            self.borderLayer.borderColor = UIColor.apptentiveTextInputBorder.cgColor

            // Even though we add our own border, this increases the size of the text field
            // so that it looks good in the (non-inset) grouped table view style.
            self.textField.borderStyle = .roundedRect

            self.borderLayer.cornerCurve = .continuous

            if case self.tableViewStyle = UITableView.Style.insetGrouped {
                self.textField.borderStyle = .none
                self.leadingConstraint?.constant = 16.0
                self.trailingConstraint?.constant = 16.0
                self.topConstraint?.constant = 0
                self.bottomConstraint?.constant = 0
                self.heightConstraint?.constant = 44
            }

        }
    }

    var borderLayer: CALayer {
        if self.tableViewStyle == UITableView.Style.insetGrouped {
            return self.layer
        } else {
            return self.textField.layer
        }
    }

    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.borderLayer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.borderLayer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
            }
        }
    }

    var leadingConstraint: NSLayoutConstraint?
    var trailingConstraint: NSLayoutConstraint?
    var topConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?
    var heightConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField(frame: .zero)
        self.tableViewStyle = .grouped
        self.isMarkedAsInvalid = false
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .apptentiveSecondaryGroupedBackground
        self.contentView.addSubview(self.textField)
        self.configureTextField()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTextField() {
        self.textField.backgroundColor = .apptentiveTextInputBackground
        self.textField.textColor = .apptentiveTextInput
        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.adjustsFontForContentSizeCategory = true
        self.textField.font = .apptentiveTextInput.apptentiveRepairedFont()
        self.textField.returnKeyType = .done
        self.textField.tintColor = .apptentivetextInputTint

        self.topConstraint = self.textField.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 1.0)
        self.leadingConstraint = self.textField.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 15.0)
        self.trailingConstraint = self.contentView.trailingAnchor.constraint(equalTo: self.textField.trailingAnchor, constant: 15.0)
        self.bottomConstraint = self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textField.bottomAnchor, multiplier: 1.0)
        self.heightConstraint = self.textField.heightAnchor.constraint(greaterThanOrEqualToConstant: 33)

        NSLayoutConstraint.activate([self.topConstraint, self.leadingConstraint, self.trailingConstraint, self.bottomConstraint, self.heightConstraint].compactMap { $0 })
    }
}
