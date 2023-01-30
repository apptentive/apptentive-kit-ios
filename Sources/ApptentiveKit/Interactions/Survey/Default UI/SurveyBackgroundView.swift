//
//  SurveyBackgroundView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/17/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyBackgroundView: UIView {
    let label: UILabel
    let disclaimerLabel: UILabel

    override init(frame: CGRect) {
        self.label = UILabel(frame: frame)
        self.disclaimerLabel = UILabel(frame: frame)
        super.init(frame: frame)

        self.configureLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureLabels() {
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.label)

        self.label.textAlignment = .center
        self.label.font = .apptentiveQuestionLabel
        self.label.numberOfLines = 0

        self.disclaimerLabel.font = .apptentiveDisclaimerLabel
        self.disclaimerLabel.textColor = .apptentiveDisclaimerLabel
        self.disclaimerLabel.adjustsFontForContentSizeCategory = true
        self.disclaimerLabel.textAlignment = .center
        self.disclaimerLabel.numberOfLines = 0
        self.disclaimerLabel.lineBreakMode = .byWordWrapping

        self.disclaimerLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.disclaimerLabel)

        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.label.trailingAnchor.constraint(equalTo: self.readableContentGuide.trailingAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.disclaimerLabel.topAnchor.constraint(equalTo: self.label.bottomAnchor, constant: 15),
            self.disclaimerLabel.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.disclaimerLabel.trailingAnchor.constraint(equalTo: self.readableContentGuide.trailingAnchor),
        ])
    }
}
