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

    override init(frame: CGRect) {
        self.label = UILabel(frame: frame)

        super.init(frame: frame)

        self.configureLabel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureLabel() {
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.label)

        self.label.textAlignment = .center
        self.label.font = .apptentiveQuestionLabel
        self.label.numberOfLines = 0

        NSLayoutConstraint.activate([
            self.label.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.label.trailingAnchor.constraint(equalTo: self.readableContentGuide.trailingAnchor),
            self.label.centerYAnchor.constraint(equalTo: self.centerYAnchor),
        ])
    }
}
