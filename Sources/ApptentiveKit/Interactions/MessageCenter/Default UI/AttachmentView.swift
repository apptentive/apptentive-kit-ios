//
//  AttachmentIndicator.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/31/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

extension MessageViewController {
    class AttachmentView: UIView {
        let imageView: UIImageView
        let titleLabel: UILabel
        let progressView: UIProgressView
        let gestureRecognizer: UIGestureRecognizer

        override init(frame: CGRect) {
            self.imageView = UIImageView(frame: frame)
            self.titleLabel = UILabel(frame: frame)
            self.progressView = UIProgressView(frame: frame)
            self.gestureRecognizer = UITapGestureRecognizer()

            super.init(frame: frame)

            self.addSubview(self.imageView)
            self.addSubview(self.titleLabel)
            self.addSubview(self.progressView)
            self.addGestureRecognizer(self.gestureRecognizer)

            self.configureViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func configureViews() {
            self.imageView.translatesAutoresizingMaskIntoConstraints = false
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.clipsToBounds = true

            self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
            self.titleLabel.font = .apptentiveMessageCenterAttachmentLabel
            self.titleLabel.textColor = self.tintColor
            self.titleLabel.textAlignment = .center
            self.titleLabel.adjustsFontForContentSizeCategory = true

            self.progressView.translatesAutoresizingMaskIntoConstraints = false

            self.isAccessibilityElement = true
            self.accessibilityTraits.insert(.button)

            self.setConstraints()
        }

        private func setConstraints() {
            NSLayoutConstraint.activate(
                [
                    self.imageView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 0.5),
                    self.imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
                    self.imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
                    self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.imageView.bottomAnchor, multiplier: 0.5),

                    self.titleLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    self.titleLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    self.widthAnchor.constraint(equalTo: self.titleLabel.widthAnchor, constant: 12),

                    self.progressView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
                    self.widthAnchor.constraint(equalTo: self.progressView.widthAnchor, constant: 12),
                    self.bottomAnchor.constraint(equalTo: self.progressView.bottomAnchor, constant: 6),

                    self.imageView.heightAnchor.constraint(equalToConstant: 44),
                    self.imageView.widthAnchor.constraint(equalTo: self.imageView.heightAnchor),
                ]
            )
        }
    }
}
