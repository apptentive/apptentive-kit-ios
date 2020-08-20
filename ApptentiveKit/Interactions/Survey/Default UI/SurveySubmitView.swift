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

    override init(frame: CGRect) {
        self.submitButton = UIButton(frame: CGRect.zero)

        super.init(frame: frame)

        self.addSubview(self.submitButton)

        self.submitButton.backgroundColor = self.tintColor
        self.submitButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        self.submitButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        self.submitButton.titleLabel?.adjustsFontForContentSizeCategory = true

        self.submitButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.submitButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitButton.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.topAnchor, multiplier: 1.0),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.submitButton.bottomAnchor, multiplier: 1.0),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.submitButton.layer.cornerRadius = self.submitButton.bounds.height / 2.0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
