//
//  SurveyViewController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/3/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import UIKit

class SurveyViewController: UIViewController {
    let viewModel: SurveyViewModel

    var scrollView: UIScrollView
    var introductionView: SurveyIntroductionView
    var stackView: UIStackView
    var submitView: SurveySubmitView

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel

        self.scrollView = UIScrollView(frame: CGRect.zero)
        self.introductionView = SurveyIntroductionView(viewModel: self.viewModel)
        self.stackView = UIStackView(arrangedSubviews: self.viewModel.questions.map({ SurveyQuestionView(viewModel: $0) }))
        self.submitView = SurveySubmitView(viewModel: self.viewModel)

        super.init(nibName: nil, bundle: nil)
    }

    required init(coder: NSCoder) {
        fatalError("initWithCoder not supported")
    }

    override func viewDidLoad() {
        self.view.backgroundColor = .white

        self.navigationItem.title = self.viewModel.title

        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.scrollView)

        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.scrollView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.scrollView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        ])

        self.scrollView.addSubview(self.introductionView)

        NSLayoutConstraint.activate([
            self.introductionView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.introductionView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            self.introductionView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
        ])

        self.stackView.axis = .vertical
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        self.stackView.spacing = 8
        self.stackView.distribution = .equalSpacing
        self.stackView.alignment = .fill
        self.scrollView.addSubview(self.stackView)

        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.introductionView.bottomAnchor),
            self.stackView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            self.stackView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
            self.stackView.widthAnchor.constraint(equalTo: self.scrollView.widthAnchor),
        ])

        self.scrollView.addSubview(self.submitView)

        NSLayoutConstraint.activate([
            self.submitView.topAnchor.constraint(equalTo: self.stackView.bottomAnchor),
            self.submitView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
            self.submitView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
            self.submitView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
        ])
    }
}
