//
//  GlassProfileView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/19/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 26, *)
class GlassProfileView: ProfileView {
    let nameGlassEffectView: UIVisualEffectView
    let emailGlassEffectView: UIVisualEffectView

    override init(frame: CGRect) {
        let glassEffect = UIGlassEffect(style: .regular)
        glassEffect.tintColor = .apptentiveSecondaryGroupedBackground
        self.nameGlassEffectView = UIVisualEffectView(effect: glassEffect)
        self.emailGlassEffectView = UIVisualEffectView(effect: glassEffect)

        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func addSubviews() {
        self.addsBorder = false

        self.nameGlassEffectView.cornerConfiguration = .capsule(maximumRadius: 26)
        self.emailGlassEffectView.cornerConfiguration = .capsule(maximumRadius: 26)

        self.nameGlassEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.emailGlassEffectView.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.nameGlassEffectView)
        self.addSubview(self.emailGlassEffectView)

        self.nameGlassEffectView.contentView.addSubview(self.nameTextField)
        self.emailGlassEffectView.contentView.addSubview(self.emailTextField)

        self.addSubview(self.errorLabel)
    }

    override func setConstraints() {
        NSLayoutConstraint.activate([
            self.nameGlassEffectView.topAnchor.constraint(equalTo: self.readableContentGuide.topAnchor),
            self.nameGlassEffectView.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.nameGlassEffectView.trailingAnchor),
            self.nameGlassEffectView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52.0),

            self.nameTextField.topAnchor.constraint(equalTo: self.nameGlassEffectView.topAnchor),
            self.nameTextField.leadingAnchor.constraint(equalTo: self.nameGlassEffectView.leadingAnchor, constant: 6),
            self.nameGlassEffectView.trailingAnchor.constraint(equalTo: self.nameTextField.trailingAnchor, constant: 6),
            self.nameGlassEffectView.bottomAnchor.constraint(equalTo: self.nameTextField.bottomAnchor),

            self.emailGlassEffectView.topAnchor.constraint(equalToSystemSpacingBelow: self.nameGlassEffectView.bottomAnchor, multiplier: 1),
            self.emailGlassEffectView.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.emailGlassEffectView.trailingAnchor),
            self.emailGlassEffectView.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),

            self.emailTextField.topAnchor.constraint(equalTo: self.emailGlassEffectView.topAnchor),
            self.emailTextField.leadingAnchor.constraint(equalTo: self.emailGlassEffectView.leadingAnchor, constant: 6),
            self.emailGlassEffectView.trailingAnchor.constraint(equalTo: self.emailTextField.trailingAnchor, constant: 10),  // make ! concentric
            self.emailGlassEffectView.bottomAnchor.constraint(equalTo: self.emailTextField.bottomAnchor),

            self.errorLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.emailGlassEffectView.bottomAnchor, multiplier: 1),
            self.errorLabel.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor, constant: 5),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.errorLabel.trailingAnchor, constant: 5),
            self.bottomAnchor.constraint(equalTo: self.errorLabel.bottomAnchor),
        ])
    }
}
