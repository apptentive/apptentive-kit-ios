//
//  MessageCenterGlassComposeView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

@available(iOS 26.0, *)
class MessageCenterGlassComposeView: MessageCenterComposeView {
    let glassEffectView: UIVisualEffectView

    override init(frame: CGRect) {
        let glassEffect = UIGlassEffect(style: .regular)
        glassEffect.tintColor = .apptentiveSecondaryGroupedBackground
        self.glassEffectView = UIVisualEffectView(effect: glassEffect)

        super.init(frame: frame)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func addSubviews() {
        self.addsBorder = false
        self.buttonInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        self.buttonConfiguration = .prominentGlass()
        self.buttonSymbolConfiguration = .init(pointSize: 20)

        self.addSubview(self.sendButton)
        self.addSubview(self.attachmentButton)
        self.addSubview(self.attachmentStackView)
        self.addSubview(self.glassEffectView)
        self.glassEffectView.contentView.addSubview(self.textView)
    }

    override func configureTextView() {
        self.glassEffectView.translatesAutoresizingMaskIntoConstraints = false
        self.glassEffectView.cornerConfiguration = .capsule(maximumRadius: 26)

        super.configureTextView()
    }

    override func setUpSpecificConstraints() {
        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalTo: self.glassEffectView.topAnchor, constant: 4),
            self.textView.leadingAnchor.constraint(equalTo: self.glassEffectView.leadingAnchor, constant: 12),
            self.glassEffectView.trailingAnchor.constraint(equalTo: self.textView.trailingAnchor, constant: 12),
            self.glassEffectView.bottomAnchor.constraint(equalTo: self.textView.bottomAnchor, constant: 4),

            self.glassEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            self.glassEffectView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.attachmentButton.trailingAnchor, multiplier: 1.0),
            self.sendButton.leadingAnchor.constraint(equalToSystemSpacingAfter: self.glassEffectView.trailingAnchor, multiplier: 1.0),

            self.attachmentStackView.topAnchor.constraint(equalToSystemSpacingBelow: self.glassEffectView.bottomAnchor, multiplier: 0.5),
            self.attachmentStackView.centerXAnchor.constraint(equalTo: self.glassEffectView.centerXAnchor),
        ])
    }
}
