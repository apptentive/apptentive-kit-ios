//
//  SurveySubmitView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/4/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import UIKit

class SurveySubmitView: UIView {
    let viewModel: SurveyViewModel
    let submitButton: UIButton

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel

        self.submitButton = Self.buildSubmitButton(submitButtonText: viewModel.submitButtonText)

        super.init(frame: CGRect.zero)

        self.translatesAutoresizingMaskIntoConstraints = false

        self.addSubview(self.submitButton)

        NSLayoutConstraint.activate([
            self.submitButton.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.submitButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            self.heightAnchor.constraint(greaterThanOrEqualToConstant: 88),
        ])

        self.backgroundColor = UIColor.lightGray
    }

    required init(coder: NSCoder) {
        fatalError("initWithCoder not supported")
    }

    static func buildSubmitButton(submitButtonText: String) -> UIButton {
        let result = UIButton(type: .system)

        result.translatesAutoresizingMaskIntoConstraints = false
        result.setTitle(submitButtonText, for: .normal)
        result.titleLabel?.adjustsFontForContentSizeCategory = true
        result.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)

        return result
    }
}
