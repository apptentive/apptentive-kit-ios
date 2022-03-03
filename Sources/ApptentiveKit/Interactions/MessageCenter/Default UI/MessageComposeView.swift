//
//  MessageCenterComposeView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Implements `intrinsicContentSize` without interfering with the autolayout of the compose view.
class MessageCenterComposeContainerView: UIView {
    let composeView: MessageCenterComposeView

    override init(frame: CGRect) {
        self.composeView = MessageCenterComposeView(frame: frame)

        super.init(frame: frame)

        self.addSubview(self.composeView)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .apptentiveGroupedBackground

        self.setUpConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let safeArea = self.bounds.inset(by: self.safeAreaInsets)

        let composeViewSize = self.composeView.systemLayoutSizeFitting(safeArea.size, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .defaultLow)

        return CGSize(width: composeViewSize.width + self.safeAreaInsets.left + self.safeAreaInsets.right, height: composeViewSize.height + self.safeAreaInsets.bottom)
    }

    private func setUpConstraints() {
        self.composeView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: self.composeView.topAnchor),
            self.leadingAnchor.constraint(equalTo: self.composeView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: self.composeView.trailingAnchor),
            self.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: self.composeView.bottomAnchor),
        ])
    }
}

class MessageCenterComposeView: UIView {
    let textView: UITextView
    let placeholderLabel: UILabel
    let separatorView: UIView
    let sendButton: UIButton
    var placeholderWidthConstraint: NSLayoutConstraint?
    var textViewHeightConstraint: NSLayoutConstraint?
    var textViewHeightLimitConstraint: NSLayoutConstraint?
    var separatorHeightConstraint: NSLayoutConstraint?
    let attachmentButton: UIButton
    let attachmentStackView: UIStackView

    override init(frame: CGRect) {
        self.textView = UITextView(frame: frame)
        self.placeholderLabel = UILabel(frame: frame)
        self.sendButton = UIButton(frame: frame)
        self.separatorView = UIView(frame: frame)
        self.attachmentButton = UIButton(frame: frame)
        self.attachmentStackView = UIStackView(frame: frame)

        super.init(frame: frame)

        self.addSubview(self.textView)
        self.addSubview(self.sendButton)
        self.addSubview(self.separatorView)
        self.addSubview(self.attachmentButton)
        self.addSubview(self.attachmentStackView)

        self.tintColor = .apptentiveSubmitButton

        self.setUpConstraints()

        self.configureTextView()
        self.configureSendButton()
        self.configureAttachmentButton()
        self.configureAttachmentStackView()

        NotificationCenter.default.addObserver(self, selector: #selector(textViewDidChange), name: UITextView.textDidChangeNotification, object: self.textView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureTextView() {
        self.textView.backgroundColor = .apptentiveTextInputBackground
        self.textView.textColor = .apptentiveTextInput
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.adjustsFontForContentSizeCategory = true
        self.textView.font = .apptentiveTextInput
        self.textView.returnKeyType = .default
        self.textView.accessibilityIdentifier = "messageTextView"

        self.separatorView.translatesAutoresizingMaskIntoConstraints = false
        self.separatorView.backgroundColor = .apptentiveTextInputBorder

        self.textView.addSubview(self.placeholderLabel)
        self.placeholderLabel.isAccessibilityElement = false
        self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.placeholderLabel.adjustsFontForContentSizeCategory = true
        self.placeholderLabel.isUserInteractionEnabled = false
        self.placeholderLabel.adjustsFontSizeToFitWidth = true
        self.placeholderLabel.minimumScaleFactor = 0.1
        self.placeholderLabel.font = .apptentiveTextInput
        self.placeholderLabel.textColor = .apptentiveTextInputPlaceholder

        self.textView.layer.cornerRadius = 6.0
        self.textView.layer.masksToBounds = false
        self.textView.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
        self.textView.clipsToBounds = true

        if #available(iOS 13.0, *) {
            self.textView.layer.cornerCurve = .continuous
        }

        self.textView.accessibilityIdentifier = "composeTextView"

        self.updatePlaceholderConstraints()
    }

    private var placeholderLayoutConstraints = [NSLayoutConstraint]()

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

    @objc func textViewDidChange() {
        self.placeholderLabel.isHidden = !self.textView.text.isEmpty
    }

    private func configureSendButton() {
        self.sendButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            self.sendButton.setPreferredSymbolConfiguration(.init(pointSize: 32.0), forImageIn: .normal)
        }
        self.sendButton.setImage(.apptentiveMessageSendButton, for: .normal)
        self.sendButton.accessibilityIdentifier = "sendButton"
    }

    private func configureAttachmentButton() {
        self.attachmentButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            self.attachmentButton.setPreferredSymbolConfiguration(.init(pointSize: 32.0), forImageIn: .normal)
        }
        self.attachmentButton.setImage(.apptentiveMessageAttachmentButton, for: .normal)
        self.attachmentButton.accessibilityIdentifier = "attachmentButton"
    }

    private func configureAttachmentStackView() {
        self.attachmentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.attachmentStackView.distribution = .equalSpacing
        self.attachmentStackView.spacing = 12.0
    }

    private func setUpConstraints() {
        self.separatorHeightConstraint = self.separatorView.heightAnchor.constraint(equalToConstant: 1.0)

        self.textViewHeightConstraint = self.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 18.0)
        self.textViewHeightConstraint?.priority = .defaultHigh
        self.textViewHeightLimitConstraint = self.textView.heightAnchor.constraint(lessThanOrEqualToConstant: 100)

        NSLayoutConstraint.activate(
            [
                self.separatorView.topAnchor.constraint(equalTo: self.topAnchor),
                self.separatorView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                self.separatorView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                self.separatorHeightConstraint,

                self.attachmentButton.centerYAnchor.constraint(equalTo: self.textView.centerYAnchor),
                self.attachmentButton.leadingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
                self.attachmentButton.heightAnchor.constraint(equalTo: self.attachmentButton.widthAnchor),

                self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0),
                self.textView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.attachmentButton.trailingAnchor, multiplier: 1.0),
                self.sendButton.leadingAnchor.constraint(equalToSystemSpacingAfter: self.textView.trailingAnchor, multiplier: 1.0),

                self.sendButton.centerYAnchor.constraint(equalTo: self.textView.centerYAnchor),
                self.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: self.sendButton.trailingAnchor, multiplier: 1),
                self.sendButton.heightAnchor.constraint(equalTo: self.sendButton.widthAnchor),

                self.attachmentStackView.topAnchor.constraint(equalToSystemSpacingBelow: self.textView.bottomAnchor, multiplier: 0.5),
                self.attachmentStackView.centerXAnchor.constraint(equalTo: self.textView.centerXAnchor),
                self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.attachmentStackView.bottomAnchor, multiplier: 0.5),

                self.textViewHeightConstraint,
                self.textViewHeightLimitConstraint,
            ].compactMap({ $0 }))
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let fineLineWidth = 1.0 / self.traitCollection.displayScale
        self.textView.layer.borderWidth = fineLineWidth
        self.separatorHeightConstraint?.constant = fineLineWidth
    }
}
