//
//  MessageReceivedCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageReceivedCell: UITableViewCell {
    let stackView: UIStackView
    let messageText: UITextView
    let profileImageView: UIImageView
    let senderLabel: UILabel
    let dateLabel: UILabel
    let bubbleImageView: UIImageView
    let attachmentStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.stackView = UIStackView(frame: .zero)
        self.messageText = UITextView(frame: .zero)
        self.dateLabel = UILabel(frame: .zero)
        self.senderLabel = UILabel(frame: .zero)
        self.profileImageView = UIImageView(frame: .zero)
        self.bubbleImageView = UIImageView(image: .apptentiveReceivedMessageBubble)
        self.attachmentStackView = UIStackView(frame: .zero)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.bubbleImageView)
        self.contentView.addSubview(self.stackView)
        self.contentView.addSubview(self.profileImageView)

        self.stackView.addArrangedSubview(self.senderLabel)
        self.stackView.addArrangedSubview(self.messageText)
        self.stackView.addArrangedSubview(self.attachmentStackView)
        self.stackView.addArrangedSubview(self.dateLabel)

        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.backgroundColor = .clear

        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.axis = .vertical
        self.stackView.alignment = .leading
        self.stackView.spacing = 8

        self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
        self.bubbleImageView.tintColor = .apptentiveMessageBubbleInbound

        self.profileImageView.translatesAutoresizingMaskIntoConstraints = false
        self.profileImageView.layer.masksToBounds = true

        self.dateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.dateLabel.numberOfLines = 0
        self.dateLabel.textColor = .apptentiveMessageLabelInbound
        self.dateLabel.font = .apptentiveMessageDateLabel
        self.dateLabel.textAlignment = .left
        self.dateLabel.adjustsFontForContentSizeCategory = true

        self.messageText.translatesAutoresizingMaskIntoConstraints = false
        self.messageText.isEditable = false
        self.messageText.isScrollEnabled = false
        self.messageText.backgroundColor = .apptentiveMessageBubbleInbound
        self.messageText.textColor = .apptentiveMessageLabelInbound
        self.messageText.font = .apptentiveMessageLabel
        self.messageText.textContainerInset = UIEdgeInsets(top: -3, left: 0, bottom: 0, right: 0)
        self.messageText.textContainer.lineFragmentPadding = 0
        self.messageText.adjustsFontForContentSizeCategory = true
        self.messageText.dataDetectorTypes = UIDataDetectorTypes.all
        self.messageText.isAccessibilityElement = true  // Make navigable via full keyboard access.

        self.senderLabel.translatesAutoresizingMaskIntoConstraints = false
        self.senderLabel.numberOfLines = 0
        self.senderLabel.textColor = .apptentiveMessageLabelInbound
        self.senderLabel.font = .apptentiveSenderLabel
        self.senderLabel.textAlignment = .left
        self.senderLabel.adjustsFontForContentSizeCategory = true

        self.attachmentStackView.translatesAutoresizingMaskIntoConstraints = false
        self.attachmentStackView.distribution = .fillProportionally
        self.attachmentStackView.spacing = 8

        self.setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint(
            item: bubbleImageView,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailing,
            multiplier: 0.75,
            constant: 0
        ).isActive = true

        let bottomConstraint = self.bubbleImageView.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor, constant: 15)
        bottomConstraint.priority = .init(751)

        NSLayoutConstraint.activate(
            [
                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.bubbleImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 40),
                self.contentView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor, constant: 10),

                self.stackView.topAnchor.constraint(equalTo: self.bubbleImageView.topAnchor, constant: 15),
                self.stackView.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 27),
                self.bubbleImageView.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor, constant: 15),
                bottomConstraint,

                self.profileImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10),
                self.profileImageView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor),
                self.profileImageView.heightAnchor.constraint(equalToConstant: 22),
                self.profileImageView.widthAnchor.constraint(equalToConstant: 22),
            ]
        )
    }

    override func layoutIfNeeded() {
        super.layoutIfNeeded()

        self.profileImageView.layer.cornerRadius = self.profileImageView.bounds.height / 2
    }
}
