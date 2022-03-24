//
//  EditProfileViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 2/7/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class EditProfileViewController: UIViewController {
    let viewModel: MessageCenterViewModel
    let profileView: ProfileFooterView

    init(viewModel: MessageCenterViewModel) {
        self.viewModel = viewModel
        self.profileView = ProfileFooterView(frame: .zero)

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

        self.profileView.emailTextField.text = self.viewModel.emailAddress
        self.profileView.emailTextField.placeholder = self.viewModel.editProfileEmailPlaceholder
        self.profileView.emailTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        self.profileView.emailTextField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)

        self.profileView.nameTextField.text = self.viewModel.name
        self.profileView.nameTextField.placeholder = self.viewModel.editProfileNamePlaceholder
        self.profileView.nameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)

        self.setConstraints()
    }

    @objc func cancel() {
        self.viewModel.cancelProfileEdits()

        self.dismiss(animated: true, completion: nil)
    }

    @objc func done() {
        self.viewModel.commitProfileEdits()

        self.dismiss(animated: true, completion: nil)
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        self.viewModel.name = self.profileView.nameTextField.text
        self.viewModel.emailAddress = self.profileView.emailTextField.text

        self.updateProfileValidation(strict: false)
    }

    @objc private func textFieldDidEndEditing(_ sender: UITextField) {
        self.updateProfileValidation(strict: true)
    }

    private func updateProfileValidation(strict: Bool) {
        if self.viewModel.profileIsValid || !strict {
            self.profileView.emailTextField.layer.borderColor = UIColor.apptentiveMessageTextViewBorder.cgColor
        } else {
            self.profileView.emailTextField.layer.borderColor = UIColor.apptentiveError.cgColor
        }

        self.navigationItem.rightBarButtonItem?.isEnabled = self.viewModel.canSendMessage
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.profileView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.profileView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: self.profileView.trailingAnchor),
            self.view.bottomAnchor.constraint(greaterThanOrEqualTo: self.profileView.bottomAnchor),
        ])
    }
}
