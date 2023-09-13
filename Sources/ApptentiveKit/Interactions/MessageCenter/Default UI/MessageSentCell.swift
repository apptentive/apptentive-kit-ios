//
//  MessageSentCell.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageSentCell: UITableViewCell {
    let stackView: UIStackView
    let messageText: UITextView
    let statusLabel: UILabel
    let bubbleImageView: UIImageView
    let attachmentStackView: UIStackView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.stackView = UIStackView(frame: .zero)
        self.messageText = UITextView(frame: .zero)
        self.statusLabel = UILabel(frame: .zero)
        self.bubbleImageView = UIImageView(image: .apptentiveSentMessageBubble)
        self.attachmentStackView = UIStackView(frame: .zero)

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.bubbleImageView)
        self.contentView.addSubview(self.stackView)

        self.stackView.addArrangedSubview(self.messageText)
        self.stackView.addArrangedSubview(self.attachmentStackView)
        self.stackView.addArrangedSubview(self.statusLabel)

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
        self.bubbleImageView.tintColor = .apptentiveMessageBubbleOutbound

        self.statusLabel.textColor = .apptentiveMessageLabelOutbound
        self.statusLabel.numberOfLines = 0
        self.statusLabel.font = .apptentiveMessageDateLabel
        self.statusLabel.textAlignment = .left
        self.statusLabel.adjustsFontForContentSizeCategory = true

        self.messageText.textColor = .apptentiveMessageLabelOutbound
        self.messageText.font = .apptentiveMessageLabel
        self.messageText.backgroundColor = .apptentiveMessageBubbleOutbound
        self.messageText.isScrollEnabled = false
        self.messageText.isEditable = false
        self.messageText.textContainerInset = UIEdgeInsets(top: -3, left: 0, bottom: 0, right: 0)
        self.messageText.textContainer.lineFragmentPadding = 0
        self.messageText.adjustsFontForContentSizeCategory = true
        self.messageText.dataDetectorTypes = UIDataDetectorTypes.all
        self.messageText.isAccessibilityElement = true  // Make navigable via full keyboard access.

        self.attachmentStackView.distribution = .fillProportionally
        self.attachmentStackView.spacing = 8.0

        setConstraints()
    }

    private func setConstraints() {
        NSLayoutConstraint(
            item: bubbleImageView,
            attribute: .leadingMargin,
            relatedBy: .equal,
            toItem: self.contentView,
            attribute: .trailingMargin,
            multiplier: 0.25,
            constant: 12
        ).isActive = true

        let bottomConstraint = self.bubbleImageView.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor, constant: 15)
        bottomConstraint.priority = .init(751)

        NSLayoutConstraint.activate(
            [
                self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                self.contentView.trailingAnchor.constraint(equalTo: self.bubbleImageView.trailingAnchor, constant: 12),
                self.contentView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor, constant: 10),

                self.stackView.topAnchor.constraint(equalTo: self.bubbleImageView.topAnchor, constant: 15),
                self.stackView.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 15),
                self.bubbleImageView.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor, constant: 25),
                bottomConstraint,
            ]
        )
    }
}
