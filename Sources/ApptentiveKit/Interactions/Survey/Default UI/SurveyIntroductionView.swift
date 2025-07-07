//
//  SurveyIntroductionView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyIntroductionView: UIView {
    let textLabel: RichTextLabel

    override init(frame: CGRect) {
        self.textLabel = RichTextLabel()

        super.init(frame: frame)

        self.addSubview(self.textLabel)

        self.textLabel.translatesAutoresizingMaskIntoConstraints = false
        self.textLabel.numberOfLines = 0
        self.textLabel.lineBreakMode = .byWordWrapping
        self.textLabel.font = .apptentiveSurveyIntroductionLabel
        self.textLabel.textStyle = .subheadline
        self.textLabel.textAlignment = .center

        self.textLabel.textColor = .apptentiveSurveyIntroduction

        NSLayoutConstraint.activate([
            self.textLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1.0),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textLabel.bottomAnchor, multiplier: 1.0),
            self.textLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: self.readableContentGuide.leadingAnchor, multiplier: 2.0),
            self.readableContentGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textLabel.trailingAnchor, multiplier: 2.0),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
