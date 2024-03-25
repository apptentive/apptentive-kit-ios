//
//  SurveyBackgroundView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/17/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyBackgroundView: UIView {
    let textView: UITextView

    var landscapeConstraints: [NSLayoutConstraint] = []
    var portraitConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        self.textView = UITextView(frame: frame)
        super.init(frame: frame)

        self.configureLabels()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureLabels() {
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.textView)

        self.textView.isEditable = false
        self.textView.isScrollEnabled = true
        self.textView.backgroundColor = .apptentiveGroupedBackground

        self.landscapeConstraints = [
            self.textView.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.readableContentGuide.trailingAnchor),
            self.textView.topAnchor.constraint(equalTo: self.readableContentGuide.topAnchor, constant: 50),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textView.bottomAnchor, multiplier: 25.0),
        ]

        self.portraitConstraints = [
            self.textView.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.textView.trailingAnchor.constraint(equalTo: self.readableContentGuide.trailingAnchor),
            self.textView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textView.bottomAnchor, multiplier: 25.0),
        ]
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let isCompact = traitCollection.verticalSizeClass == .compact
        NSLayoutConstraint.deactivate(isCompact ? self.portraitConstraints : self.landscapeConstraints)
        NSLayoutConstraint.activate(isCompact ? self.landscapeConstraints : self.portraitConstraints)
    }
}
