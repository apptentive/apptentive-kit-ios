//
//  MessageReceivedCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageReceivedCell: UITableViewCell {
    let messageLabel: UILabel
    let profileImageView: ApptentiveImageView
    let senderLabel: UILabel
    let dateLabel: UILabel
    let bubbleImageView: UIImageView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.messageLabel = UILabel(frame: .zero)
        self.dateLabel = UILabel(frame: .zero)
        self.senderLabel = UILabel(frame: .zero)
        self.profileImageView = ApptentiveImageView()
        self.bubbleImageView = UIImageView(image: .apptentiveReceivedMessageBubble)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.bubbleImageView)
        // TODO: Should bubbleImageView be a subview or just a backgound?

        self.bubbleImageView.addSubview(self.senderLabel)
        self.bubbleImageView.addSubview(self.messageLabel)
        self.bubbleImageView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.profileImageView)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = .clear

        self.messageLabel.textColor = .apptentiveMessageLabelInbound
        self.senderLabel.textColor = .apptentiveMessageLabelInbound
        self.dateLabel.textColor = .apptentiveMessageLabelInbound

        self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.bubbleImageView.tintColor = .apptentiveMessageBubbleInbound

        self.profileImageView.translatesAutoresizingMaskIntoConstraints = false
        self.profileImageView.layer.masksToBounds = true
        self.profileImageView.layer.cornerRadius = 8

        self.dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.dateLabel.numberOfLines = 0
        self.dateLabel.font = .apptentiveMessageDateLabel
        self.dateLabel.textAlignment = .left

        self.messageLabel.font = .apptentiveMessageLabel
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.messageLabel.numberOfLines = 0
        self.messageLabel.lineBreakMode = .byWordWrapping
        self.messageLabel.adjustsFontSizeToFitWidth = true
        self.messageLabel.minimumScaleFactor = 0.5
        self.messageLabel.sizeToFit()
        self.messageLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)

        self.senderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.senderLabel.numberOfLines = 0
        self.senderLabel.font = .apptentiveSenderLabel
        self.senderLabel.textAlignment = .left

        self.setConstraints()
    }

    private func setConstraints() {
        bubbleImageView.sizeToFit()

        NSLayoutConstraint.activate(
            [
                self.senderLabel.topAnchor.constraint(equalTo: self.bubbleImageView.topAnchor, constant: 10),
                self.senderLabel.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 30),
                self.senderLabel.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: -10),
                self.senderLabel.heightAnchor.constraint(equalToConstant: 10),

                self.messageLabel.topAnchor.constraint(equalTo: self.senderLabel.bottomAnchor, constant: 10),
                self.messageLabel.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 30),
                self.messageLabel.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: -10),
                self.messageLabel.bottomAnchor.constraint(equalTo: self.dateLabel.topAnchor, constant: -10),

                self.dateLabel.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 30),
                self.dateLabel.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: 0),
                self.bubbleImageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.dateLabel.bottomAnchor, multiplier: 2.0),
                self.dateLabel.heightAnchor.constraint(equalToConstant: 10),

                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.bubbleImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 40),
                self.self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bubbleImageView.bottomAnchor, multiplier: 2.0),
                // TODO: Make width flexible for different size classes?
                self.bubbleImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),

                self.profileImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10),
                self.profileImageView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor),
                self.profileImageView.heightAnchor.constraint(equalToConstant: 22),
                self.profileImageView.widthAnchor.constraint(equalToConstant: 22),
            ]
        )
    }
}
