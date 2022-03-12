//
//  QuestionCardView.swift
//  SurveyCard
//
//  Created by Frank Schmitt on 5/5/21.
//

import UIKit

class QuestionCardView: UIView {
    let stackView: UIStackView
    let introductionLabel: UILabel
    let questionLabel: UILabel
    let instructionsLabel: UILabel
    let errorLabel: UILabel

    override init(frame: CGRect) {
        self.stackView = UIStackView(frame: frame)
        self.introductionLabel = UILabel(frame: frame)
        self.questionLabel = UILabel(frame: frame)
        self.instructionsLabel = UILabel(frame: frame)
        self.errorLabel = UILabel(frame: frame)

        super.init(frame: frame)

        self.setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpViews() {
        self.introductionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.introductionLabel)

        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.stackView)

        NSLayoutConstraint.activate([
            self.introductionLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.safeAreaLayoutGuide.topAnchor, multiplier: 1.0),
            self.introductionLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1.0),
            self.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: self.introductionLabel.trailingAnchor, multiplier: 1.0),
            self.stackView.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: self.introductionLabel.bottomAnchor, multiplier: 1.0),
            self.stackView.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            self.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor, constant: 8),
        ])

        self.stackView.axis = .vertical
        self.stackView.alignment = .fill
        self.stackView.spacing = 12

        self.stackView.addArrangedSubview(self.questionLabel)
        self.stackView.addArrangedSubview(self.instructionsLabel)

        self.introductionLabel.numberOfLines = 0
        self.introductionLabel.textAlignment = .center
        self.introductionLabel.font = .apptentiveSurveyIntroductionLabel
        self.introductionLabel.textColor = .apptentiveSurveyIntroduction
        self.introductionLabel.adjustsFontForContentSizeCategory = true

        self.questionLabel.numberOfLines = 0
        self.questionLabel.font = .apptentiveQuestionLabel
        self.questionLabel.textColor = .apptentiveQuestionLabel
        self.questionLabel.adjustsFontForContentSizeCategory = true

        self.instructionsLabel.numberOfLines = 0
        self.instructionsLabel.font = .apptentiveInstructionsLabel
        self.instructionsLabel.textColor = .apptentiveInstructionsLabel
        self.instructionsLabel.adjustsFontForContentSizeCategory = true

        self.errorLabel.numberOfLines = 0
        self.errorLabel.font = .apptentiveInstructionsLabel
        self.errorLabel.textColor = .apptentiveError
        self.errorLabel.adjustsFontForContentSizeCategory = true
    }
}
