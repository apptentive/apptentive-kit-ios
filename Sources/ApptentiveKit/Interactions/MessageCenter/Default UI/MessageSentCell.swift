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
    let messageLabel: UILabel
    let dateLabel: UILabel
    let bubbleImageView: UIImageView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.messageLabel = UILabel(frame: .zero)
        self.dateLabel = UILabel(frame: .zero)
        self.bubbleImageView = UIImageView(image: .apptentiveSentMessageBubble)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.contentView.addSubview(self.bubbleImageView)
        // TODO: Should this be a subview or just a backgound?
        self.bubbleImageView.addSubview(self.messageLabel)
        self.bubbleImageView.addSubview(self.dateLabel)

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

        self.messageLabel.textColor = .apptentiveMessageLabelOutbound
        self.messageLabel.font = .apptentiveMessageLabel
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.messageLabel.numberOfLines = 0
        self.messageLabel.lineBreakMode = .byWordWrapping
        self.messageLabel.adjustsFontSizeToFitWidth = true
        self.messageLabel.minimumScaleFactor = 0.5
        self.messageLabel.sizeToFit()
        self.messageLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        self.messageLabel.adjustsFontForContentSizeCategory = true

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint.activate(
            [
                self.messageLabel.topAnchor.constraint(equalTo: self.bubbleImageView.topAnchor, constant: 10),
                self.messageLabel.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 10),
                self.messageLabel.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: -30),
                self.messageLabel.bottomAnchor.constraint(equalTo: self.dateLabel.topAnchor, constant: -10),

                self.dateLabel.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 10),
                self.dateLabel.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: 30),
                self.bubbleImageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.dateLabel.bottomAnchor, multiplier: 2.0),
                self.dateLabel.heightAnchor.constraint(equalToConstant: 10),

                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.bubbleImageView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -30),
                self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.bubbleImageView.bottomAnchor, multiplier: 2.0),
                self.bubbleImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            ]
        )
    }
}
