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
    let greetingBodyLabel: UILabel
    let brandingImageView: ApptentiveImageView
    let innerStackView: UIStackView
    let outerStackView: UIStackView

    override init(frame: CGRect) {
        self.greetingTitleLabel = UILabel(frame: .zero)
        self.greetingBodyLabel = UILabel(frame: .zero)
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
        self.greetingTitleLabel.numberOfLines = 0
        self.greetingTitleLabel.lineBreakMode = .byWordWrapping
        self.greetingTitleLabel.font = .apptentiveMessageCenterGreetingTitle
        self.greetingTitleLabel.textAlignment = .center
        self.greetingTitleLabel.textColor = .apptentiveMessageCenterGreetingTitle
        self.greetingTitleLabel.adjustsFontForContentSizeCategory = true

        self.greetingBodyLabel.translatesAutoresizingMaskIntoConstraints = false
        self.greetingBodyLabel.numberOfLines = 0
        self.greetingBodyLabel.lineBreakMode = .byWordWrapping
        self.greetingBodyLabel.font = .apptentiveMessageCenterGreetingBody
        self.greetingBodyLabel.textAlignment = .center
        self.greetingBodyLabel.textColor = .apptentiveMessageCenterGreetingBody
        self.greetingBodyLabel.adjustsFontForContentSizeCategory = true

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
        self.innerStackView.addArrangedSubview(self.greetingBodyLabel)

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
            self.outerStackView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 2),
            self.outerStackView.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
            self.readableContentGuide.trailingAnchor.constraint(equalTo: self.outerStackView.trailingAnchor),
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
