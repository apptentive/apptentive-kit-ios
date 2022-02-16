//
//  MessageReceivedCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageReceivedCell: UITableViewCell {
    let messageText: UITextView
    let profileImageView: ApptentiveImageView
    let senderLabel: UILabel
    let dateLabel: UILabel
    let bubbleImageView: UIImageView
    let attachmentStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.messageText = UITextView(frame: .zero)
        self.dateLabel = UILabel(frame: .zero)
        self.senderLabel = UILabel(frame: .zero)
        self.profileImageView = ApptentiveImageView()
        self.bubbleImageView = UIImageView(image: .apptentiveReceivedMessageBubble)
        self.attachmentStackView = UIStackView(frame: .zero)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.bubbleImageView)
        self.contentView.addSubview(self.senderLabel)
        self.contentView.addSubview(self.messageText)
        self.contentView.addSubview(self.dateLabel)
        self.contentView.addSubview(self.profileImageView)
        self.contentView.addSubview(self.attachmentStackView)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = .clear

        self.messageText.textColor = .apptentiveMessageLabelInbound
        self.senderLabel.textColor = .apptentiveMessageLabelInbound
        self.dateLabel.textColor = .apptentiveMessageLabelInbound

        self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.bubbleImageView.tintColor = .apptentiveMessageBubbleInbound

        self.profileImageView.translatesAutoresizingMaskIntoConstraints = false
        self.profileImageView.layer.masksToBounds = true

        self.dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.dateLabel.numberOfLines = 0
        self.dateLabel.font = .apptentiveMessageDateLabel
        self.dateLabel.textAlignment = .left
        self.dateLabel.adjustsFontForContentSizeCategory = true

        self.messageText.font = .apptentiveMessageLabel
        self.messageText.translatesAutoresizingMaskIntoConstraints = false
        self.messageText.isEditable = false
        self.messageText.isScrollEnabled = false
        self.messageText.backgroundColor = .apptentiveMessageBubbleInbound
        self.messageText.sizeToFit()
        self.messageText.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.messageText.adjustsFontForContentSizeCategory = true

        self.senderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.senderLabel.numberOfLines = 0
        self.senderLabel.font = .apptentiveSenderLabel
        self.senderLabel.textAlignment = .left
        self.senderLabel.adjustsFontForContentSizeCategory = true

        self.attachmentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.attachmentStackView.distribution = .fillProportionally
        self.attachmentStackView.spacing = 8

        self.setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate(
            [
                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.bubbleImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 40),
                self.contentView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor, constant: 10),
                self.contentView.trailingAnchor.constraint(greaterThanOrEqualTo: self.bubbleImageView.trailingAnchor, constant: 30),

                self.senderLabel.topAnchor.constraint(equalTo: self.bubbleImageView.topAnchor, constant: 10),
                self.senderLabel.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 20),
                self.bubbleImageView.trailingAnchor.constraint(equalTo: self.senderLabel.trailingAnchor, constant: 10),

                self.messageText.topAnchor.constraint(equalTo: self.senderLabel.bottomAnchor, constant: 10),
                self.messageText.leadingAnchor.constraint(equalTo: self.senderLabel.leadingAnchor),
                self.messageText.trailingAnchor.constraint(equalTo: self.senderLabel.trailingAnchor),

                self.attachmentStackView.topAnchor.constraint(equalTo: self.messageText.bottomAnchor, constant: 5),
                self.attachmentStackView.leadingAnchor.constraint(equalTo: self.messageText.leadingAnchor),
                self.attachmentStackView.trailingAnchor.constraint(lessThanOrEqualTo: self.messageText.trailingAnchor),

                self.dateLabel.topAnchor.constraint(equalTo: self.attachmentStackView.bottomAnchor, constant: 5),
                self.dateLabel.leadingAnchor.constraint(equalTo: self.senderLabel.leadingAnchor),
                self.dateLabel.trailingAnchor.constraint(equalTo: self.senderLabel.trailingAnchor),
                self.bubbleImageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.dateLabel.bottomAnchor, multiplier: 2.0),

                self.profileImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10),
                self.profileImageView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor),
                self.profileImageView.heightAnchor.constraint(equalToConstant: 22),
                self.profileImageView.widthAnchor.constraint(equalToConstant: 22),
            ]
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.height / 2
    }
}
