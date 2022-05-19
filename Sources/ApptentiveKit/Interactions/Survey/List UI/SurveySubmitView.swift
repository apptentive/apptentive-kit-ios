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

    override init(frame: CGRect) {
        self.submitButton = UIButton(frame: .zero)
        self.submitLabel = UILabel(frame: .zero)

        super.init(frame: frame)

        self.addSubview(self.submitButton)
        self.addSubview(self.submitLabel)

        self.submitButton.backgroundColor = UIColor.apptentiveSubmitButton
        self.submitButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        self.submitButton.titleLabel?.font = .apptentiveSubmitButtonTitle
        self.submitButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.submitButton.layer.borderWidth = .apptentiveButtonBorderWidth
        self.submitButton.layer.borderColor = UIColor.apptentiveSubmitButtonBorder.cgColor
        self.submitButton.setTitleColor(.apptentiveSubmitButtonTitle, for: .normal)

        self.submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.submitButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitButton.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.topAnchor, multiplier: 1.0),
        ])

        self.submitLabel.font = .apptentiveSubmitLabel
        self.submitLabel.adjustsFontForContentSizeCategory = true
        self.submitLabel.textAlignment = .center
        self.submitLabel.isHidden = true
        self.submitLabel.numberOfLines = 2
        self.submitLabel.lineBreakMode = .byWordWrapping

        self.submitLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.submitLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitLabel.topAnchor.constraint(equalTo: self.submitButton.bottomAnchor, constant: 10),
            self.submitLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.submitLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.submitButton.bottomAnchor, multiplier: 7.0),
        ])
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
