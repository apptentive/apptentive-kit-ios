//
//  SurveyMultiLineCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import UIKit

class SurveyMultiLineCell: UITableViewCell {
    let textView: UITextView
    var heightConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textView = UITextView(frame: CGRect.zero)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textView)
        self.configureTextView()

        if #available(iOS 13.0, *) {
            self.layer.borderColor = UIColor.tertiaryLabel.cgColor
            self.layer.borderWidth = 1.0
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTextView() {
        self.textView.translatesAutoresizingMaskIntoConstraints = false
        self.textView.adjustsFontForContentSizeCategory = true

        self.textView.font = .preferredFont(forTextStyle: .body)
        self.textView.returnKeyType = .done

        NSLayoutConstraint.activate([
            self.textView.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 1.0),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textView.bottomAnchor, multiplier: 1.0),
            self.textView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.contentView.leadingAnchor, multiplier: 1.0),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textView.trailingAnchor, multiplier: 1.0),
        ])

        self.heightConstraint = self.textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100.0)
        self.heightConstraint?.isActive = true
    }
}
