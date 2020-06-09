//
//  SurveyIntroductionView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/4/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import UIKit

class SurveyIntroductionView: UIView {
    let viewModel: SurveyViewModel
    let label: UILabel

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel

        self.label = Self.buildIntroductionLabel(introduction: viewModel.introduction)

        super.init(frame: CGRect.zero)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.label)

        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(equalToSystemSpacingBelow: self.topAnchor, multiplier: 1),
            self.label.leadingAnchor.constraint(equalToSystemSpacingAfter: self.safeAreaLayoutGuide.leadingAnchor, multiplier: 1),
            self.bottomAnchor.constraint(equalToSystemSpacingBelow: self.label.bottomAnchor, multiplier: 1),
            self.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: self.label.trailingAnchor, multiplier: 1),
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])

        self.backgroundColor = .lightGray
    }

    required init(coder: NSCoder) {
        fatalError("initWithCoder not supported")
    }

    static func buildIntroductionLabel(introduction: String) -> UILabel {
        let result = UILabel(frame: CGRect.zero)

        result.text = introduction

        result.translatesAutoresizingMaskIntoConstraints = false
        result.numberOfLines = 0
        result.font = .preferredFont(forTextStyle: .body)
        result.adjustsFontForContentSizeCategory = true

        return result
    }
}
