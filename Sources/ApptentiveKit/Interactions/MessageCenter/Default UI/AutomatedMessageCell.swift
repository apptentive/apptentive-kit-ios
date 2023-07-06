//
//  AutomatedMessageCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/15/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

extension MessageCenterViewController {

    class AutomatedMessageCell: UITableViewCell {

        let messageText: UITextView
        let bubbleImageView: UIImageView

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            self.messageText = UITextView(frame: .zero)
            self.bubbleImageView = UIImageView(image: .apptentiveReceivedMessageBubble)

            super.init(style: .default, reuseIdentifier: reuseIdentifier)
            self.contentView.addSubview(self.bubbleImageView)
            self.contentView.addSubview(self.messageText)

            setupViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            self.backgroundColor = .clear
            self.bubbleImageView.translatesAutoresizingMaskIntoConstraints = false
            self.bubbleImageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            self.bubbleImageView.tintColor = .apptentiveMessageBubbleInbound

            self.messageText.textColor = .apptentiveMessageLabelInbound
            self.messageText.font = .apptentiveMessageLabel
            self.messageText.translatesAutoresizingMaskIntoConstraints = false
            self.messageText.backgroundColor = .apptentiveMessageBubbleInbound
            self.messageText.isScrollEnabled = false
            self.messageText.isEditable = false
            self.messageText.sizeToFit()
            self.messageText.setContentHuggingPriority(.defaultHigh, for: .vertical)
            self.messageText.adjustsFontForContentSizeCategory = true
            self.messageText.dataDetectorTypes = UIDataDetectorTypes.all

            setConstraints()
        }

        private func setConstraints() {
            NSLayoutConstraint.activate(
                [
                    self.bubbleImageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 10),
                    self.bubbleImageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10),
                    self.contentView.trailingAnchor.constraint(greaterThanOrEqualTo: self.bubbleImageView.trailingAnchor, constant: 60),
                    self.contentView.bottomAnchor.constraint(equalTo: self.bubbleImageView.bottomAnchor, constant: 10),

                    self.messageText.topAnchor.constraint(equalToSystemSpacingBelow: self.bubbleImageView.topAnchor, multiplier: 1),
                    self.messageText.leadingAnchor.constraint(equalTo: self.bubbleImageView.leadingAnchor, constant: 20),
                    self.bubbleImageView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.messageText.trailingAnchor, multiplier: 1),
                    self.bubbleImageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.messageText.bottomAnchor, multiplier: 1),
                ]
            )
        }
    }
}
