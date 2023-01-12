//
//  DialogViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/15/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

/// A class used to display TextModal ("Note") and EnjoymentDialog ("Love Dialog") interactions.
public class DialogViewController: UIViewController, DialogViewModelDelegate {

    let viewModel: DialogViewModel
    var dialogView: DialogView
    var buttons: [DialogButton] = []
    var buttonRadiusIsCustom: Bool = false

    // swift-format-ignore
    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .init(white: 0, alpha: 0.2)
        self.view.isOpaque = false

        self.dialogView.titleLabel.text = self.viewModel.title
        self.dialogView.messageLabel.text = self.viewModel.message
        self.dialogView.isMessageLabelHidden = self.viewModel.message == nil
        self.view.addSubview(dialogView)

        self.configureButtons()

        self.setConstraints()
    }

    init(viewModel: DialogViewModel) {
        self.viewModel = viewModel
        self.dialogView = DialogView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Dialog announcement", bundle: .module, value: "Alert", comment: "Announcement when a dialog is presented."))

        super.viewDidAppear(animated)
    }

    // MARK: Targets

    @objc func dialogButtonTapped(sender: UIButton) {
        self.viewModel.buttonSelected(at: sender.tag)
    }

    // MARK: TextModalViewModelDelegate

    // swift-format-ignore
    public func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    // MARK: Private

    private func configureButtons() {
        for (position, action) in self.viewModel.actions.enumerated() {
            let button: DialogButton = {
                switch action.actionType {
                case .dismiss:
                    return DismissButton(frame: .zero)

                case .interaction:
                    return InteractionButton(frame: .zero)

                case .no:
                    return NoButton(frame: .zero)

                case .yes:
                    return YesButton(frame: .zero)
                }
            }()

            button.addTarget(self, action: #selector(dialogButtonTapped), for: .touchUpInside)
            button.tag = position
            button.setTitle(action.label, for: .normal)

            self.dialogView.buttonStackView.addArrangedSubview(button)
        }
    }

    private func setConstraints() {
        self.dialogView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.dialogView.topAnchor.constraint(greaterThanOrEqualTo: self.view.readableContentGuide.topAnchor, constant: 20),
            self.dialogView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.dialogView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.dialogView.widthAnchor.constraint(lessThanOrEqualToConstant: 270),
            self.dialogView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.readableContentGuide.bottomAnchor, constant: 20),
        ])
    }
}
