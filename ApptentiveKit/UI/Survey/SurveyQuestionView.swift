//
//  SurveyQuestionView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/3/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import UIKit

class SurveyQuestionView: UIStackView {
    let viewModel: SurveyViewModel.Question

    init(viewModel: SurveyViewModel.Question) {
        self.viewModel = viewModel
        super.init(frame: CGRect.zero)

        self.axis = .vertical

        self.translatesAutoresizingMaskIntoConstraints = false

        self.addArrangedSubview(Self.buildQuestionLabel(question: viewModel.text))
        self.addArrangedSubview(Self.buildInstructionsLabel(from: viewModel))
        self.addArrangedSubview(Self.buildQuestionArea())

        self.layoutMargins = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)
        self.isLayoutMarginsRelativeArrangement = true

        let backgroundView = UIView(frame: self.bounds)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.insertSubview(backgroundView, at: 0)

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])

        backgroundView.layer.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        backgroundView.layer.cornerRadius = 8
    }

    required init(coder: NSCoder) {
        fatalError("initWithCoder not supported")
    }

    static func buildQuestionLabel(question: String) -> UILabel {
        let result = UILabel(frame: CGRect.zero)

        result.text = question

        result.translatesAutoresizingMaskIntoConstraints = false
        result.numberOfLines = 0
        result.font = .preferredFont(forTextStyle: .title2)
        result.adjustsFontForContentSizeCategory = true

        return result
    }

    static func buildInstructionsLabel(from viewModel: SurveyViewModel.Question) -> UILabel {
        let result = UILabel(frame: CGRect.zero)

        result.text = viewModel.instructionsText

        result.translatesAutoresizingMaskIntoConstraints = false
        result.numberOfLines = 0
        result.font = .preferredFont(forTextStyle: .footnote)
        result.adjustsFontForContentSizeCategory = true

        result.textColor = .gray

        return result
    }

    static func buildQuestionArea() -> UIView {
        let result = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        result.translatesAutoresizingMaskIntoConstraints = false
        result.heightAnchor.constraint(equalToConstant: 100).isActive = true

        return result
    }
}
