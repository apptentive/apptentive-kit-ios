//
//  ProfileView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 2/3/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

class ProfileView: UIView {
    let nameTextField: UITextField
    let emailTextField: UITextField
    let errorLabel: UILabel
    var addsBorder = true

    override init(frame: CGRect) {
        self.nameTextField = UITextField(frame: .zero)
        self.emailTextField = UITextField(frame: .zero)
        self.errorLabel = UILabel(frame: .zero)

        super.init(frame: frame)

        self.addSubviews()

        configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var emailValid: Bool = true {
        didSet {
            self.emailTextField.layer.borderColor = (emailValid ? UIColor.apptentiveTextInputBorder : UIColor.apptentiveError).cgColor
            self.errorLabel.isHidden = emailValid
            self.emailTextField.rightView?.isHidden = emailValid
        }
    }

    func addSubviews() {
        self.addSubview(self.nameTextField)
        self.addSubview(self.emailTextField)
        self.addSubview(self.errorLabel)
    }

    private func configureViews() {
        let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.nameTextField.bounds.height))
        let secondSpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.emailTextField.bounds.height))

        self.nameTextField.translatesAutoresizingMaskIntoConstraints = false
        self.nameTextField.adjustsFontForContentSizeCategory = true

        if self.addsBorder {
            self.nameTextField.layer.borderWidth = 1 / self.traitCollection.displayScale
            self.nameTextField.layer.masksToBounds = false
            self.nameTextField.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor
            self.nameTextField.layer.cornerRadius = 5
            self.nameTextField.backgroundColor = .apptentiveTextInputBackground
        } else {
            self.nameTextField.backgroundColor = .clear
        }

        self.nameTextField.leftView = spacerView
        self.nameTextField.leftViewMode = .always
        self.nameTextField.contentVerticalAlignment = .center
        self.nameTextField.font = .apptentiveMessageCenterTextInput
        self.nameTextField.textColor = .apptentiveMessageCenterTextInput
        self.nameTextField.returnKeyType = .next
        self.nameTextField.autocapitalizationType = .words
        self.nameTextField.accessibilityIdentifier = "name"

        self.emailTextField.translatesAutoresizingMaskIntoConstraints = false
        self.emailTextField.adjustsFontForContentSizeCategory = true

        if self.addsBorder {
            self.emailTextField.layer.borderWidth = 1 / self.traitCollection.displayScale
            self.emailTextField.layer.masksToBounds = false
            self.emailTextField.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor
            self.emailTextField.layer.cornerRadius = 5
            self.emailTextField.backgroundColor = .apptentiveTextInputBackground
        } else {
            self.emailTextField.backgroundColor = .clear
            let emailErrorImage = UIImage(systemName: "exclamationmark.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium))?.withRenderingMode(.alwaysTemplate)
            let emailErrorView = UIImageView(image: emailErrorImage)
            emailErrorView.tintColor = .apptentiveError
            self.emailTextField.rightView = emailErrorView
            self.emailTextField.rightViewMode = .always
            self.emailTextField.rightView?.isHidden = true
        }

        self.emailTextField.leftView = secondSpacerView
        self.emailTextField.leftViewMode = .always
        self.emailTextField.contentVerticalAlignment = .center
        self.emailTextField.font = .apptentiveMessageCenterTextInput
        self.emailTextField.textColor = .apptentiveMessageCenterTextInput
        self.emailTextField.keyboardType = .emailAddress
        self.emailTextField.returnKeyType = .done
        self.emailTextField.autocapitalizationType = .none
        self.emailTextField.accessibilityIdentifier = "email"

        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.adjustsFontForContentSizeCategory = true
        self.errorLabel.numberOfLines = 0
        self.errorLabel.lineBreakMode = .byWordWrapping
        self.errorLabel.font = .apptentiveInstructionsLabel
        self.errorLabel.textColor = .apptentiveError

        setConstraints()
    }

    internal func setConstraints() {
        NSLayoutConstraint.activate([
            self.nameTextField.topAnchor.constraint(equalTo: self.readableContentGuide.topAnchor),
            self.nameTextField.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.nameTextField.trailingAnchor),
            self.nameTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            self.emailTextField.topAnchor.constraint(equalToSystemSpacingBelow: self.nameTextField.bottomAnchor, multiplier: 1),
            self.emailTextField.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.emailTextField.trailingAnchor),
            self.emailTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            self.errorLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.emailTextField.bottomAnchor, multiplier: 1),
            self.errorLabel.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor, constant: 5),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.errorLabel.trailingAnchor, constant: 5),
            self.bottomAnchor.constraint(equalTo: self.errorLabel.bottomAnchor),
        ])
    }
}
