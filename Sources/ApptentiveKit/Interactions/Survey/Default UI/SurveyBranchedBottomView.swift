//
//  SurveyBranchedBottomView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 7/25/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

class SurveyBranchedBottomView: UIView {

    var nextButton: UIButton
    var termsAndConditions: UIButton
    var buttonContainerView: UIView
    var stackView: UIStackView
    var stackViewHeightConstraint: NSLayoutConstraint
    var surveyIndicator: SurveyIndicator

    override init(frame: CGRect) {
        self.surveyIndicator = SurveyIndicator(frame: frame)
        self.nextButton = UIButton(frame: frame)
        self.termsAndConditions = UIButton(frame: frame)
        self.buttonContainerView = UIView(frame: frame)
        self.stackView = UIStackView(frame: frame)
        self.stackViewHeightConstraint = self.stackView.heightAnchor.constraint(equalToConstant: 160)
        self.stackViewHeightConstraint.priority = .defaultHigh
        super.init(frame: frame)
        self.addSubview(self.stackView)
        self.buttonContainerView.addSubview(self.nextButton)
        self.setConstraints()
        self.backgroundColor = .apptentiveBranchedSurveyFooter
        self.configureNextButton()
        self.configureSurveyIndicator()
        self.configureTermsAndConditions()
        self.configureButtonContainer()
        self.configureStackView()
    }

    init(frame: CGRect, numberOfSegments: Int) {
        self.surveyIndicator = SurveyIndicator(frame: frame, numberOfSegments: numberOfSegments)
        self.nextButton = UIButton(frame: frame)
        self.termsAndConditions = UIButton(frame: frame)
        self.buttonContainerView = UIView(frame: frame)
        self.stackView = UIStackView(frame: frame)
        self.stackViewHeightConstraint = self.stackView.heightAnchor.constraint(equalToConstant: 160)
        self.stackViewHeightConstraint.priority = .defaultHigh
        super.init(frame: frame)
        self.addSubview(self.stackView)
        self.buttonContainerView.addSubview(self.nextButton)
        self.setConstraints()
        self.backgroundColor = .apptentiveSubmitButton
        self.configureNextButton()
        self.configureSurveyIndicator()
        self.configureTermsAndConditions()
        self.configureButtonContainer()
        self.configureStackView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        switch UIButton.apptentiveStyle {
        case .pill:
            self.nextButton.layer.cornerRadius = self.nextButton.bounds.height / 2.0
        case .radius(let radius):
            self.nextButton.layer.cornerRadius = radius
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.nextButton.backgroundColor = UIColor.apptentiveSubmitButton
    }

    private func configureButtonContainer() {
        self.buttonContainerView.backgroundColor = .apptentiveGroupedBackground
        self.buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureTermsAndConditions() {
        self.termsAndConditions.titleLabel?.textAlignment = .center
        self.termsAndConditions.titleLabel?.textColor = .apptentiveTermsOfServiceLabel
        self.termsAndConditions.titleLabel?.font = .apptentiveTermsOfServiceLabel
        self.termsAndConditions.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureSurveyIndicator() {
        self.surveyIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.surveyIndicator.backgroundColor = .apptentiveGroupedBackground
    }

    private func configureNextButton() {
        self.nextButton.backgroundColor = UIColor.apptentiveSubmitButton
        self.nextButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        self.nextButton.titleLabel?.font = .apptentiveSubmitButtonTitle
        self.nextButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.nextButton.layer.borderWidth = .apptentiveButtonBorderWidth
        self.nextButton.layer.borderColor = UIColor.apptentiveSubmitButtonBorder.cgColor
        self.nextButton.setTitleColor(.apptentiveSubmitButtonTitle, for: .normal)
        self.nextButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.nextButton.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureStackView() {
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.addArrangedSubview(self.buttonContainerView)
        self.stackView.addArrangedSubview(self.surveyIndicator)
        self.stackView.addArrangedSubview(self.termsAndConditions)
        self.stackView.axis = .vertical
        self.stackView.distribution = .fillEqually
        self.stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.topAnchor),
            self.stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            self.stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            self.stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.stackViewHeightConstraint,
            self.nextButton.centerXAnchor.constraint(equalTo: self.buttonContainerView.centerXAnchor),
            self.nextButton.topAnchor.constraint(equalTo: self.buttonContainerView.topAnchor, constant: 10),
            self.buttonContainerView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.nextButton.bottomAnchor, multiplier: 0.5),

        ])
    }

}
