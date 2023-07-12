//
//  StatusView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/10/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import UIKit

extension MessageCenterViewController {
    class StatusView: UIView {
        let label: UILabel

        override init(frame: CGRect) {
            self.label = UILabel(frame: frame)

            super.init(frame: frame)

            self.addSubview(self.label)

            self.setUpLabel()
            self.setUpConstraints()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setUpLabel() {
            self.label.numberOfLines = 0
            self.label.lineBreakMode = .byWordWrapping
            self.label.font = .apptentiveMessageCenterStatus
            self.label.textColor = .apptentiveMessageCenterStatus
            self.label.textAlignment = .center
            self.label.adjustsFontForContentSizeCategory = true
        }

        private func setUpConstraints() {
            self.label.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                self.label.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1),
                self.label.leadingAnchor.constraint(equalTo: self.readableContentGuide.leadingAnchor),
                self.readableContentGuide.trailingAnchor.constraint(equalTo: self.label.trailingAnchor),
                self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.label.bottomAnchor, multiplier: 1),
            ])
        }

        override var intrinsicContentSize: CGSize {
            var result = self.label.systemLayoutSizeFitting(self.bounds.size)

            result.height += 16

            return result
        }
    }
}
