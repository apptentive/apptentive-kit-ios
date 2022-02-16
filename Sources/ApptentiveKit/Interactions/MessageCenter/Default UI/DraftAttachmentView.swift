//
//  DraftAttachmentView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/7/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

extension MessageViewController {
    class DraftAttachmentView: UIView {
        let imageView: UIImageView
        let gestureRecognizer: UIGestureRecognizer
        let closeButton: UIButton

        override init(frame: CGRect) {
            self.imageView = UIImageView(frame: frame)
            self.gestureRecognizer = UITapGestureRecognizer()
            self.closeButton = UIButton(frame: frame)

            super.init(frame: frame)

            self.addSubview(self.imageView)
            self.addGestureRecognizer(self.gestureRecognizer)
            self.addSubview(self.closeButton)

            self.configureViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func configureViews() {
            self.imageView.translatesAutoresizingMaskIntoConstraints = false
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.clipsToBounds = true

            self.closeButton.translatesAutoresizingMaskIntoConstraints = false
            self.closeButton.setImage(.apptentiveAttachmentRemoveButton, for: .normal)
            self.closeButton.tintColor = .apptentiveError
            self.closeButton.imageView?.backgroundColor = .white
            self.closeButton.imageView?.layer.cornerRadius = 11
            self.closeButton.accessibilityIdentifier = "delete"

            self.gestureRecognizer.accessibilityLabel = "View Attachment"

            self.setConstraints()
        }

        private func setConstraints() {
            NSLayoutConstraint.activate(
                [
                    self.imageView.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1),
                    self.imageView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.leadingAnchor, multiplier: 1),
                    self.trailingAnchor.constraint(equalToSystemSpacingAfter: self.imageView.trailingAnchor, multiplier: 0),
                    self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.imageView.bottomAnchor, multiplier: 0),

                    self.closeButton.centerYAnchor.constraint(equalTo: self.imageView.topAnchor),
                    self.closeButton.centerXAnchor.constraint(equalTo: self.imageView.leadingAnchor),
                    self.closeButton.heightAnchor.constraint(equalToConstant: 32),
                    self.closeButton.widthAnchor.constraint(equalTo: self.closeButton.heightAnchor),

                    self.heightAnchor.constraint(equalToConstant: 58),
                    self.widthAnchor.constraint(equalToConstant: 58),
                ]
            )
        }
    }
}
