//
//  MessageSentCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

//FIXME: The sent bubble image right corner is cutoff.
class MessageSentCell: UITableViewCell {
    let messageText: UITextView
    let dateLabel: UILabel
    let bubbleImageView: UIImageView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.messageText = UITextView(frame: .zero)
        self.dateLabel = UILabel(frame: .zero)
        self.bubbleImageView = UIImageView(image: .apptentiveSentMessageBubble)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.bubbleImageView)
        self.contentView.addSubview(self.messageText)
        self.contentView.addSubview(self.dateLabel)

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

        self.dateLabel.textColor = .apptentiveMessageLabelOutbound
        self.dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.dateLabel.numberOfLines = 0
        self.dateLabel.font = .apptentiveMessageDateLabel
        self.dateLabel.textAlignment = .left
        self.dateLabel.adjustsFontForContentSizeCategory = true

        self.messageText.textColor = .apptentiveMessageLabelOutbound
        self.messageText.font = .apptentiveMessageLabel
        self.messageText.translatesAutoresizingMaskIntoConstraints = false
        self.messageText.backgroundColor = .apptentiveMessageBubbleOutbound
        self.messageText.isScrollEnabled = false
        self.messageText.isEditable = false
        self.messageText.sizeToFit()
        self.messageText.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.messageText.adjustsFontForContentSizeCategory = true

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate(
            [
                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.bubbleImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -10),
                self.bubbleImageView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -10),
                self.bubbleImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 60),

                self.messageText.topAnchor.constraint(equalTo: self.bubbleImageView.topAnchor, constant: 10),
                self.messageText.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 10),
                self.messageText.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: -30),
                self.messageText.bottomAnchor.constraint(equalTo: self.dateLabel.topAnchor, constant: -10),
                self.messageText.heightAnchor.constraint(greaterThanOrEqualTo: self.dateLabel.heightAnchor, multiplier: 2.0),

                self.dateLabel.leadingAnchor.constraint(equalTo: self.messageText.leadingAnchor),
                self.dateLabel.trailingAnchor.constraint(equalTo: self.messageText.trailingAnchor),
                self.bubbleImageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.dateLabel.bottomAnchor, multiplier: 2.0),
            ]
        )
    }
}
