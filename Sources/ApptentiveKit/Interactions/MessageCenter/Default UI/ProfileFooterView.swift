//
//  ProfileFooterView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 2/3/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

class ProfileFooterView: UIView {

    let nameTextField: UITextField
    let emailTextField: UITextField

    override init(frame: CGRect) {
        self.nameTextField = UITextField(frame: .zero)
        self.emailTextField = UITextField(frame: .zero)

        super.init(frame: frame)

        self.addSubview(self.nameTextField)
        self.addSubview(self.emailTextField)

        configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.nameTextField.bounds.height))
        let secondSpacerView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: self.emailTextField.bounds.height))

        self.nameTextField.translatesAutoresizingMaskIntoConstraints = false
        self.nameTextField.layer.borderWidth = 1 / self.traitCollection.displayScale
        self.nameTextField.layer.masksToBounds = false
        self.nameTextField.layer.borderColor = UIColor.apptentiveMessageCenterTextViewBorder.cgColor
        self.nameTextField.layer.cornerRadius = 5
        self.nameTextField.leftView = spacerView
        self.nameTextField.leftViewMode = .always
        self.nameTextField.contentVerticalAlignment = .center
        self.nameTextField.font = .apptentiveTextInput
        self.nameTextField.textColor = .apptentiveTextInput
        self.emailTextField.autocapitalizationType = .words
        self.nameTextField.tag = 0
        self.nameTextField.accessibilityIdentifier = "name"

        self.emailTextField.translatesAutoresizingMaskIntoConstraints = false
        self.emailTextField.layer.borderWidth = 1 / self.traitCollection.displayScale
        self.emailTextField.layer.masksToBounds = false
        self.emailTextField.layer.borderColor = UIColor.apptentiveMessageCenterTextViewBorder.cgColor
        self.emailTextField.layer.cornerRadius = 5
        self.emailTextField.leftView = secondSpacerView
        self.emailTextField.leftViewMode = .always
        self.emailTextField.contentVerticalAlignment = .center
        self.emailTextField.font = .apptentiveTextInput
        self.emailTextField.textColor = .apptentiveTextInput
        self.emailTextField.tag = 1
        self.emailTextField.keyboardType = .emailAddress
        self.emailTextField.autocapitalizationType = .none
        self.emailTextField.accessibilityIdentifier = "email"

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.nameTextField.topAnchor.constraint(equalToSystemSpacingBelow: self.readableContentGuide.topAnchor, multiplier: 1),
            self.nameTextField.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.nameTextField.trailingAnchor),
            self.nameTextField.heightAnchor.constraint(equalToConstant: 40),

            self.emailTextField.topAnchor.constraint(equalToSystemSpacingBelow: self.nameTextField.bottomAnchor, multiplier: 1),
            self.emailTextField.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.emailTextField.trailingAnchor),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.emailTextField.bottomAnchor, multiplier: 1),
            self.emailTextField.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

}
