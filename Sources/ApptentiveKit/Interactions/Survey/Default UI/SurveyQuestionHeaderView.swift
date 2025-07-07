//
//  SurveyQuestionHeaderView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/5/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyQuestionHeaderView: UITableViewHeaderFooterView {
    let stackView: UIStackView
    let questionLabel: RichTextLabel
    let instructionsLabel: UILabel

    override init(reuseIdentifier: String?) {
        self.questionLabel = RichTextLabel(frame: .zero)
        self.instructionsLabel = UILabel(frame: .zero)
        self.stackView = UIStackView(arrangedSubviews: [self.questionLabel, self.instructionsLabel])
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .apptentiveGroupedBackground
        self.contentView.addSubview(self.stackView)

        self.configureLabels()
        self.configureStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureLabels() {
        self.questionLabel.textStyle = .headline
        self.questionLabel.numberOfLines = 0
        self.questionLabel.lineBreakMode = .byWordWrapping
        self.questionLabel.font = .apptentiveQuestionLabel
        self.questionLabel.textColor = .apptentiveQuestionLabel
        self.instructionsLabel.adjustsFontForContentSizeCategory = true
        self.instructionsLabel.numberOfLines = 0
        self.instructionsLabel.lineBreakMode = .byWordWrapping
        self.instructionsLabel.font = .apptentiveInstructionsLabel
        self.instructionsLabel.textColor = .apptentiveInstructionsLabel

    }

    private func configureStackView() {
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.axis = .vertical
        self.stackView.spacing = 8.0

        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 3.0),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.stackView.bottomAnchor, multiplier: 1.0),
            self.stackView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.contentView.leadingAnchor, multiplier: 2.0),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.stackView.trailingAnchor, multiplier: 2.0),
        ])
    }
}
