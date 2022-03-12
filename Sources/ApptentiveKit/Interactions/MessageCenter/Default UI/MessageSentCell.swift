//
//  MessageSentCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageSentCell: UITableViewCell {
    let messageText: UITextView
    let statusLabel: UILabel
    let bubbleImageView: UIImageView
    let attachmentStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.messageText = UITextView(frame: .zero)
        self.statusLabel = UILabel(frame: .zero)
        self.bubbleImageView = UIImageView(image: .apptentiveSentMessageBubble)
        self.attachmentStackView = UIStackView(frame: .zero)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.bubbleImageView)
        self.contentView.addSubview(self.messageText)
        self.contentView.addSubview(self.statusLabel)
        self.contentView.addSubview(self.attachmentStackView)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = .clear
        self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        self.bubbleImageView.tintColor = .apptentiveMessageBubbleOutbound

        self.statusLabel.textColor = .apptentiveMessageLabelOutbound
        self.statusLabel.translatesAutoresizingMaskIntoConstraints = false
        self.statusLabel.numberOfLines = 0
        self.statusLabel.font = .apptentiveMessageDateLabel
        self.statusLabel.textAlignment = .left
        self.statusLabel.adjustsFontForContentSizeCategory = true

        self.messageText.textColor = .apptentiveMessageLabelOutbound
        self.messageText.font = .apptentiveMessageLabel
        self.messageText.translatesAutoresizingMaskIntoConstraints = false
        self.messageText.backgroundColor = .apptentiveMessageBubbleOutbound
        self.messageText.isScrollEnabled = false
        self.messageText.isEditable = false
        self.messageText.sizeToFit()
        self.messageText.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.messageText.adjustsFontForContentSizeCategory = true

        self.attachmentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.attachmentStackView.distribution = .fillProportionally
        self.attachmentStackView.spacing = 8.0

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate(
            [
                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.contentView.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: 10),
                self.contentView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor, constant: 10),
                self.bubbleImageView.leadingAnchor.constraint(greaterThanOrEqualTo: self.contentView.leadingAnchor, constant: 60),

                self.messageText.topAnchor.constraint(equalToSystemSpacingBelow: self.bubbleImageView.topAnchor, multiplier: 1),
                self.messageText.leadingAnchor.constraint(equalToSystemSpacingAfter: self.bubbleImageView.leadingAnchor, multiplier: 1),
                self.bubbleImageView.trailingAnchor.constraint(equalTo: self.messageText.trailingAnchor, constant: 20),

                self.attachmentStackView.topAnchor.constraint(equalToSystemSpacingBelow: self.messageText.bottomAnchor, multiplier: 0.5),
                self.attachmentStackView.leadingAnchor.constraint(equalTo: self.messageText.leadingAnchor),
                self.attachmentStackView.trailingAnchor.constraint(lessThanOrEqualTo: self.messageText.trailingAnchor),

                self.statusLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.attachmentStackView.bottomAnchor, multiplier: 0.5),
                self.statusLabel.leadingAnchor.constraint(equalTo: self.messageText.leadingAnchor),
                self.statusLabel.trailingAnchor.constraint(equalTo: self.messageText.trailingAnchor),
                self.bubbleImageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.statusLabel.bottomAnchor, multiplier: 1),
            ]
        )
    }
}
