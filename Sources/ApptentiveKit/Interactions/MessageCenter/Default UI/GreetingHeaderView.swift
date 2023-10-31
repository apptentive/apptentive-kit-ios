//
//  GreetingHeaderView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class GreetingHeaderView: UIView {

    let greetingTitleLabel: UILabel
    let greetingBodyText: UITextView
    let brandingImageView: ApptentiveImageView
    let innerStackView: UIStackView
    let outerStackView: UIStackView

    override init(frame: CGRect) {
        self.greetingTitleLabel = UILabel(frame: .zero)
        self.greetingBodyText = UITextView(frame: .zero)
        self.brandingImageView = ApptentiveImageView()
        self.innerStackView = UIStackView(frame: .zero)
        self.outerStackView = UIStackView(frame: .zero)
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.greetingTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.greetingTitleLabel.font = .apptentiveMessageCenterGreetingTitle
        self.greetingTitleLabel.textAlignment = .center
        self.greetingTitleLabel.textColor = .apptentiveMessageCenterGreetingTitle
        self.greetingTitleLabel.adjustsFontForContentSizeCategory = true
        self.greetingTitleLabel.isAccessibilityElement = true

        self.greetingTitleLabel.accessibilityRespondsToUserInteraction = true

        self.greetingBodyText.translatesAutoresizingMaskIntoConstraints = false
        self.greetingBodyText.font = .apptentiveMessageCenterGreetingBody
        self.greetingBodyText.textAlignment = .center
        self.greetingBodyText.textColor = .apptentiveMessageCenterGreetingBody
        self.greetingBodyText.adjustsFontForContentSizeCategory = true
        self.greetingBodyText.dataDetectorTypes = UIDataDetectorTypes.all
        self.greetingBodyText.isScrollEnabled = false
        self.greetingBodyText.isEditable = false
        self.greetingBodyText.textContainerInset = .zero
        self.greetingBodyText.textContainer.lineFragmentPadding = 0
        self.greetingBodyText.backgroundColor = .apptentiveMessageCenterBackground
        self.greetingBodyText.isAccessibilityElement = true

        self.brandingImageView.translatesAutoresizingMaskIntoConstraints = false
        self.brandingImageView.layer.masksToBounds = true
        self.brandingImageView.layer.cornerRadius = 10
        self.brandingImageView.contentMode = .scaleAspectFit

        self.innerStackView.translatesAutoresizingMaskIntoConstraints = false
        self.innerStackView.axis = .vertical
        self.innerStackView.alignment = .center
        self.innerStackView.distribution = .equalSpacing
        self.innerStackView.spacing = 16

        self.innerStackView.addArrangedSubview(self.greetingTitleLabel)
        self.innerStackView.addArrangedSubview(self.greetingBodyText)

        self.outerStackView.translatesAutoresizingMaskIntoConstraints = false
        self.outerStackView.axis = self.traitCollection.verticalSizeClass == .compact ? .horizontal : .vertical
        self.outerStackView.alignment = .center
        self.outerStackView.distribution = .equalSpacing
        self.outerStackView.spacing = 16

        self.outerStackView.addArrangedSubview(self.brandingImageView)
        self.outerStackView.addArrangedSubview(self.innerStackView)

        self.addSubview(outerStackView)

        setConstraints()
    }

    private func setConstraints() {
        let brandingHeightConstraint = self.brandingImageView.heightAnchor.constraint(equalToConstant: 100)
        brandingHeightConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            brandingHeightConstraint,
            self.brandingImageView.widthAnchor.constraint(equalToConstant: 100),
            self.outerStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.outerStackView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 2),
            self.outerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(greaterThanOrEqualTo: self.outerStackView.trailingAnchor),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.outerStackView.bottomAnchor, multiplier: 2),
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.translatesAutoresizingMaskIntoConstraints = false

        self.outerStackView.axis = self.traitCollection.verticalSizeClass == .compact ? .horizontal : .vertical

        self.outerStackView.layoutIfNeeded()

        self.translatesAutoresizingMaskIntoConstraints = true

        self.sizeToFit()
    }
}
