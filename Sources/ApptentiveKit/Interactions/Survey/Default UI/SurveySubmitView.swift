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
    let submitLabel: UILabel
    let disclaimerLabel: UILabel

    override init(frame: CGRect) {
        self.submitButton = UIButton(frame: .zero)
        self.submitLabel = UILabel(frame: .zero)
        self.disclaimerLabel = UILabel(frame: .zero)
        super.init(frame: frame)

        self.addSubview(self.submitButton)

        self.addSubview(self.submitLabel)
        self.addSubview(self.disclaimerLabel)

        self.submitButton.backgroundColor = UIColor.apptentiveSubmitButton
        self.submitButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        self.submitButton.titleLabel?.font = .apptentiveSubmitButtonTitle
        self.submitButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.submitButton.layer.borderWidth = .apptentiveButtonBorderWidth
        self.submitButton.layer.borderColor = UIColor.apptentiveSubmitButtonBorder.cgColor
        self.submitButton.layer.shadowOpacity = 1.0
        self.submitButton.layer.shadowRadius = 3.0
        self.submitButton.layer.shadowOffset = .zero
        self.submitButton.setTitleColor(.apptentiveSubmitButtonTitle, for: .normal)

        self.submitButton.translatesAutoresizingMaskIntoConstraints = false

        let multiplier = UITableView.apptentiveQuestionSeparatorHeight == 0 ? 1.0 : 3.5

        NSLayoutConstraint.activate([
            self.submitButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitButton.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.topAnchor, multiplier: multiplier),
        ])

        self.submitLabel.font = .apptentiveSubmitStatusLabel
        self.submitLabel.adjustsFontForContentSizeCategory = true
        self.submitLabel.textAlignment = .center
        self.submitLabel.numberOfLines = 0
        self.submitLabel.isHidden = true
        self.submitLabel.lineBreakMode = .byWordWrapping

        self.submitLabel.translatesAutoresizingMaskIntoConstraints = false

        self.disclaimerLabel.font = .apptentiveDisclaimerLabel
        self.disclaimerLabel.textColor = .apptentiveDisclaimerLabel
        self.disclaimerLabel.adjustsFontForContentSizeCategory = true
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

    override func layoutSubviews() {
        super.layoutSubviews()

        switch UIButton.apptentiveStyle {
        case .pill:
            self.submitButton.layer.cornerRadius = self.submitButton.bounds.height / 2.0
        case .radius(let radius):
            self.submitButton.layer.cornerRadius = radius
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.submitButton.backgroundColor = UIColor.apptentiveSubmitButton
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
