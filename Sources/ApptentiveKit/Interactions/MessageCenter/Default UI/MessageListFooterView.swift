//
//  MessageListFooterView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageListFooterView: UIView {

    let statusTextLabel: UILabel

    override init(frame: CGRect) {
        self.statusTextLabel = UILabel(frame: frame)
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.statusTextLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusTextLabel.numberOfLines = 0
        self.statusTextLabel.lineBreakMode = .byWordWrapping
        self.statusTextLabel.font = .apptentiveMessageCenterStatusMessage
        self.statusTextLabel.textColor = .apptentiveMessageCenterStatus
        self.statusTextLabel.textAlignment = .center
        self.statusTextLabel.adjustsFontForContentSizeCategory = true
        self.addSubview(statusTextLabel)
        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.statusTextLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.readableContentGuide.topAnchor, multiplier: 1),
            self.statusTextLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: self.readableContentGuide.leadingAnchor, multiplier: 1),
            self.readableContentGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: self.statusTextLabel.trailingAnchor, multiplier: 1),
            self.readableContentGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: self.statusTextLabel.bottomAnchor, multiplier: 1),
        ])
    }
}
