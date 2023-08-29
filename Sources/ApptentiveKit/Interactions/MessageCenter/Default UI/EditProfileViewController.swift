//
//  EditProfileViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 2/7/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController, UITextFieldDelegate {
    let viewModel: MessageCenterViewModel
    let profileView: ProfileView

    init(viewModel: MessageCenterViewModel) {
        self.viewModel = viewModel
        self.profileView = ProfileView(frame: .zero)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = self.viewModel.editProfileViewTitle
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))

        self.view.backgroundColor = .apptentiveGroupedBackground
        self.view.addSubview(self.profileView)

        self.profileView.translatesAutoresizingMaskIntoConstraints = false

        self.profileView.nameTextField.text = self.viewModel.name
        self.profileView.nameTextField.attributedPlaceholder = NSAttributedString(string: self.viewModel.editProfileNamePlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.apptentiveMessageCenterTextInputPlaceholder])
        self.profileView.nameTextField.accessibilityLabel = self.viewModel.editProfileNamePlaceholder
        self.profileView.nameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        self.profileView.nameTextField.delegate = self

        self.profileView.emailTextField.text = self.viewModel.emailAddress
        self.profileView.emailTextField.attributedPlaceholder = NSAttributedString(string: self.viewModel.editProfileEmailPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: UIColor.apptentiveMessageCenterTextInputPlaceholder])
        self.profileView.emailTextField.accessibilityLabel = self.viewModel.editProfileEmailPlaceholder
        self.profileView.emailTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        self.profileView.emailTextField.delegate = self

        self.profileView.errorLabel.text = self.viewModel.profileEmailInvalidError
        self.profileView.errorLabel.isHidden = true

        self.setConstraints()

        self.profileView.nameTextField.becomeFirstResponder()
    }

    // MARK: - Actions

    @objc func cancel() {
        self.viewModel.cancelProfileEdits()

        self.dismiss(animated: true, completion: nil)
    }

    @objc func done() {
        self.viewModel.commitProfileEdits()

        self.dismiss(animated: true, completion: nil)
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        if sender == self.profileView.nameTextField {
            self.viewModel.name = self.profileView.nameTextField.text
        } else if sender == self.profileView.emailTextField {
            self.viewModel.emailAddress = self.profileView.emailTextField.text
        }

        self.updateProfileValidation(strict: false)
    }

    // MARK: - Text Field Delegate

    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.apptentiveTextInputBorderSelected.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor
        self.updateProfileValidation(strict: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.profileView.nameTextField {
            self.profileView.emailTextField.becomeFirstResponder()
        } else if self.viewModel.profileIsValid {
            self.done()
        } else {
            self.updateProfileValidation(strict: true)
        }

        return true
    }

    private func updateProfileValidation(strict: Bool) {
        if self.viewModel.profileIsValid || !strict {
            self.profileView.emailTextField.layer.borderColor = UIColor.apptentiveMessageCenterTextInputBorder.cgColor
            self.profileView.errorLabel.isHidden = true
        } else {
            self.profileView.emailTextField.layer.borderColor = UIColor.apptentiveError.cgColor
            self.profileView.errorLabel.isHidden = false
            UIAccessibility.post(notification: .screenChanged, argument: self.profileView.errorLabel)
        }

        self.navigationItem.rightBarButtonItem?.isEnabled = self.viewModel.profileIsValid
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.profileView.topAnchor.constraint(equalToSystemSpacingBelow: self.view.topAnchor, multiplier: 1),
            self.profileView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: self.profileView.trailingAnchor),
            self.view.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.profileView.bottomAnchor, multiplier: 1),
        ])
    }
}
