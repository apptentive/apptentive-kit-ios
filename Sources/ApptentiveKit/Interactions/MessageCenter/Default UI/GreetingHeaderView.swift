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
    let brandingImageView: UIImageView
    let stackView: UIStackView

    override init(frame: CGRect) {
        self.greetingTitleLabel = UILabel(frame: .zero)
        self.greetingBodyLabel = UILabel(frame: .zero)
        self.brandingImageView = UIImageView(frame: .zero)
        self.stackView = UIStackView(frame: .zero)
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
        self.brandingImageView.image = .apptentiveMessageHeader
        self.brandingImageView.tintColor = .apptentiveBrandingImage
        self.brandingImageView.contentMode = .scaleAspectFit

        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.axis = .vertical
        self.stackView.alignment = .center
        self.stackView.distribution = .equalSpacing
        self.stackView.spacing = 8
        self.stackView.spacing = 0

        self.stackView.addArrangedSubview(self.brandingImageView)
        self.stackView.addArrangedSubview(self.greetingTitleLabel)
        self.stackView.addArrangedSubview(self.greetingBodyLabel)

        self.addSubview(stackView)

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.brandingImageView.widthAnchor.constraint(equalToConstant: 50),
            self.brandingImageView.heightAnchor.constraint(equalToConstant: 50),
            self.stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 5),
            self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20),
            self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20),
            self.stackView.heightAnchor.constraint(equalTo: self.heightAnchor),
        ])
    }

}
