//
//  SurveySubmitView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveySubmitView: UIView {
    let submitButton: UIButton
    let submitLabel: RichTextLabel
    let disclaimerLabel: RichTextLabel

    override init(frame: CGRect) {
        self.submitButton = UIButton(frame: .zero)
        self.submitLabel = RichTextLabel(frame: .zero)
        self.disclaimerLabel = RichTextLabel(frame: .zero)
        super.init(frame: frame)

        self.addSubview(self.submitButton)

        self.addSubview(self.submitLabel)
        self.addSubview(self.disclaimerLabel)

        self.submitButton.configuration = .filled()
        self.submitButton.tintColor = UIColor.apptentiveSubmitButton
        self.submitButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var container = incoming
            container.foregroundColor = .apptentiveSubmitButtonTitle
            container.font = .apptentiveSubmitButtonTitle

            return container
        }

        self.submitButton.layer.borderWidth = .apptentiveButtonBorderWidth
        self.submitButton.layer.borderColor = UIColor.apptentiveSubmitButtonBorder.cgColor
        self.submitButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        switch UIButton.apptentiveStyle {
        case .pill:
            self.submitButton.configuration?.cornerStyle = .capsule
        case .radius:
            self.submitButton.configuration?.cornerStyle = .dynamic
        }
        self.submitButton.layer.shadowOpacity = 1.0
        self.submitButton.layer.shadowRadius = 3.0
        self.submitButton.layer.shadowOffset = .zero
        self.submitButton.setTitleColor(.apptentiveSubmitButtonTitle, for: .normal)

        self.submitButton.translatesAutoresizingMaskIntoConstraints = false
        self.submitButton.titleLabel?.adjustsFontForContentSizeCategory = true

        let multiplier = UITableView.apptentiveQuestionSeparatorHeight == 0 ? 1.0 : 3.5

        NSLayoutConstraint.activate([
            self.submitButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitButton.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.topAnchor, multiplier: multiplier),
        ])

        self.submitLabel.font = .apptentiveSubmitStatusLabel
        self.submitLabel.textStyle = .headline
        self.submitLabel.textAlignment = .center
        self.submitLabel.numberOfLines = 0
        self.submitLabel.isHidden = true
        self.submitLabel.lineBreakMode = .byWordWrapping

        self.submitLabel.translatesAutoresizingMaskIntoConstraints = false

        self.disclaimerLabel.font = .apptentiveDisclaimerLabel
        self.disclaimerLabel.textColor = .apptentiveDisclaimerLabel
        self.disclaimerLabel.textStyle = .callout
        self.disclaimerLabel.textAlignment = .center
        self.disclaimerLabel.numberOfLines = 0
        self.disclaimerLabel.lineBreakMode = .byWordWrapping

        self.disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([

            self.submitLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitLabel.topAnchor.constraint(equalTo: self.submitButton.bottomAnchor, constant: 10),
            self.submitLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.submitLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.disclaimerLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.disclaimerLabel.topAnchor.constraint(equalTo: self.submitLabel.bottomAnchor, constant: 10),
            self.disclaimerLabel.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.disclaimerLabel.trailingAnchor.constraint(equalTo: self.readableContentGuide.trailingAnchor),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.disclaimerLabel.bottomAnchor, multiplier: 5.0),
        ])
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        let submitButtonDidFocus = context.nextFocusedItem === self.submitButton

        coordinator.addCoordinatedAnimations {
            self.submitButton.layer.shadowColor = submitButtonDidFocus ? UIColor.systemBlue.cgColor : UIColor.clear.cgColor
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.submitButton.tintColor = UIColor.apptentiveSubmitButton
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
