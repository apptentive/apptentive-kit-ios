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

    static let widthConstant: CGFloat = 270
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
        self.dialogView.isMessageHidden = self.viewModel.message == nil || self.viewModel.message?.isEmpty == true

        self.view.addSubview(dialogView)

        self.configureButtons()

        self.setConstraints()

        self.dialogViewModel(viewModel, didLoadImage: viewModel.image)
    }

    init(viewModel: DialogViewModel) {
        self.viewModel = viewModel
        self.dialogView = DialogView(frame: .zero, collapseImageBottomPadding: self.viewModel.dialogOnlyContainsImage, dialogType: self.viewModel.dialogType)
        super.init(nibName: nil, bundle: nil)
        viewModel.delegate = self

        self.dialogViewModel(viewModel, didLoadImage: viewModel.image)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Dialog announcement", bundle: .apptentive, value: "Alert", comment: "Announcement when a dialog is presented."))

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

    public func dialogViewModel(_: DialogViewModel, didLoadImage imageData: DialogViewModel.Image) {
        switch imageData {
        case .loaded(let image, let accessibilityLabel, let layout, let maxHeight):
            self.dialogView.headerImageAlternateLabel.text = nil
            self.dialogView.headerImageView.image = image
            self.dialogView.headerImageView.accessibilityLabel = accessibilityLabel
            self.dialogView.headerImageView.isAccessibilityElement = true
            self.dialogView.headerImageView.contentMode = layout.contentMode(for: self.traitCollection)
            self.dialogView.imageInset = layout.imageInset
            self.updateAspectRatioConstraintAndMaxHeight(image: image, maxWidth: DialogViewController.widthConstant, maxHeight: maxHeight, contentMode: layout.contentMode(for: self.traitCollection))
        case .loading(let altText, let layout):
            self.dialogView.headerImageAlternateLabel.text = altText
            self.dialogView.headerImageView.image = nil
            self.dialogView.headerImageView.accessibilityLabel = nil
            self.dialogView.headerImageView.isAccessibilityElement = false
            self.dialogView.imageInset = layout.imageInset

        case .none:
            self.dialogView.headerImageAlternateLabel.text = nil
            self.dialogView.headerImageView.image = nil
            self.dialogView.headerImageView.accessibilityLabel = nil
            self.dialogView.headerImageView.isAccessibilityElement = false
        }
    }

    // MARK: Private
    private func updateAspectRatioConstraintAndMaxHeight(image: UIImage, maxWidth: CGFloat, maxHeight: CGFloat, contentMode: UIView.ContentMode) {
        let aspectRatio = max(image.size.width, 1) / max(image.size.height, 1)
        let height = max(maxWidth, 1) / aspectRatio

        self.dialogView.headerImageViewAspectConstraint = self.dialogView.headerImageView.heightAnchor.constraint(equalTo: self.dialogView.headerImageView.widthAnchor, multiplier: 1.0 / aspectRatio)
        self.dialogView.headerImageViewAspectConstraint.priority = .defaultLow

        var fitPriority: UILayoutPriority = (contentMode == .scaleAspectFit) ? .defaultHigh : .defaultLow

        //If the image is too wide for a center/left/right alignment we set its alignment to fit and retain the image inset to avoid the image being cropped.
        let horizontalMargin = self.dialogView.headerImageView.layoutMargins.left + self.dialogView.headerImageView.layoutMargins.right
        let verticalMargin = self.dialogView.headerImageView.layoutMargins.top + self.dialogView.headerImageView.layoutMargins.bottom
        if image.size.width + horizontalMargin > DialogViewController.widthConstant && (contentMode == .left || contentMode == .right || contentMode == .center) {
            if (image.size.height + verticalMargin) > maxHeight {
                self.dialogView.imageInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            } else {
                self.dialogView.imageInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            }
            self.dialogView.headerImageView.contentMode = .scaleAspectFit
            fitPriority = .defaultHigh
        }

        self.dialogView.headerImageViewHeightConstraint = self.dialogView.headerImageView.heightAnchor.constraint(lessThanOrEqualToConstant: height)
        self.dialogView.headerImageViewHeightConstraint.priority = fitPriority
        if !self.viewModel.dialogOnlyContainsImage {
            self.dialogView.headerImageViewBottomConstraint = self.dialogView.titleLabel.topAnchor.constraint(equalTo: self.dialogView.headerImageView.bottomAnchor, constant: 20)
        }
        NSLayoutConstraint.activate([
            self.dialogView.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight),
            self.dialogView.headerImageView.widthAnchor.constraint(equalToConstant: maxWidth),
            self.dialogView.headerImageViewHeightConstraint,
            self.dialogView.headerImageViewAspectConstraint,
            self.dialogView.headerImageViewBottomConstraint,
        ])
    }

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
            self.configureButtonAxis()
            self.dialogView.buttonStackView.addArrangedSubview(button)
        }
    }

    private func configureButtonAxis() {

        if self.viewModel.dialogType == .textModal && self.viewModel.actions.count > 2 {
            self.dialogView.buttonStackView.axis = .vertical
        } else {
            self.viewModel.actions.forEach { action in
                if action.label.count > 13 {
                    self.dialogView.buttonStackView.axis = .vertical
                } else {
                    self.dialogView.buttonStackView.axis = .horizontal
                }
            }
        }
    }

    private func setConstraints() {
        self.dialogView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.dialogView.topAnchor.constraint(greaterThanOrEqualTo: self.view.readableContentGuide.topAnchor, constant: 20),
            self.dialogView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.dialogView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.dialogView.widthAnchor.constraint(equalToConstant: DialogViewController.widthConstant),
            self.dialogView.bottomAnchor.constraint(lessThanOrEqualTo: self.view.readableContentGuide.bottomAnchor, constant: 20),
        ])
    }
}
