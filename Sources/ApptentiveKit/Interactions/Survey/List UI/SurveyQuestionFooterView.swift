//
//  SurveyQuestionFooter.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 5/28/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

class SurveyQuestionFooterView: UITableViewHeaderFooterView {

    let errorLabel: UILabel
    let separatorLine: UIView

    override init(reuseIdentifier: String?) {
        self.errorLabel = UILabel(frame: .zero)
        self.separatorLine = UIView(frame: .zero)
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .clear

        self.contentView.addSubview(self.errorLabel)
        self.contentView.addSubview(self.separatorLine)

        self.configureViews()
    }

    private func configureViews() {
        self.errorLabel.translatesAutoresizingMaskIntoConstraints = false
        self.errorLabel.adjustsFontForContentSizeCategory = true
        self.errorLabel.numberOfLines = 0
        self.errorLabel.lineBreakMode = .byWordWrapping
        self.errorLabel.font = .apptentiveInstructionsLabel
        self.errorLabel.textColor = .apptentiveError

        self.separatorLine.translatesAutoresizingMaskIntoConstraints = false
        self.separatorLine.backgroundColor = .apptentiveQuestionSeparator

        let errorBottomConstraint =
            UITableView.apptentiveQuestionSeparatorHeight == 0
            ? self.contentView.bottomAnchor.constraint(equalTo: self.errorLabel.bottomAnchor, constant: 2) : self.separatorLine.topAnchor.constraint(equalToSystemSpacingBelow: self.errorLabel.bottomAnchor, multiplier: 1.0)

        NSLayoutConstraint.activate([
            self.errorLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 7),
            self.errorLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: self.contentView.leadingAnchor, multiplier: 2),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.errorLabel.trailingAnchor, multiplier: 2),

            errorBottomConstraint,

            self.separatorLine.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.separatorLine.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.separatorLine.bottomAnchor),

            self.errorLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 8),
            self.separatorLine.heightAnchor.constraint(equalToConstant: UITableView.apptentiveQuestionSeparatorHeight),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
