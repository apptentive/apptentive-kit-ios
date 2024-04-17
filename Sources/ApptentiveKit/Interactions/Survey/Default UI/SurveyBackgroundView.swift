//
//  SurveyBackgroundView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/17/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyBackgroundView: UIView {
    var textView: UITextView

    var landscapeConstraints: [NSLayoutConstraint] = []
    var portraitConstraints: [NSLayoutConstraint] = []

    override init(frame: CGRect) {
        self.textView = UITextView(frame: frame)
        super.init(frame: frame)

        self.configureLabels()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
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
        self.textView.dataDetectorTypes = .all

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

        NSLayoutConstraint.activate(self.portraitConstraints)
    }

    @objc func orientationDidChange() {
        let isLandscape = UIDevice.current.orientation.isLandscape
        NSLayoutConstraint.deactivate(isLandscape ? self.portraitConstraints : self.landscapeConstraints)
        NSLayoutConstraint.activate(isLandscape ? self.landscapeConstraints : self.portraitConstraints)
    }
}
