//
//  SurveyViewController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, SurveyViewModelDelegate, UIAdaptivePresentationControllerDelegate {
    let viewModel: SurveyViewModel
    let introductionView: SurveyIntroductionView
    let submitView: SurveySubmitView
    let thankYouLabel: UILabel

    var hasSubmitted: Bool = false

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel
        self.introductionView = SurveyIntroductionView(frame: .zero)
        self.submitView = SurveySubmitView(frame: .zero)
        self.thankYouLabel = UILabel(frame: .zero)

        if #available(iOS 13.0, *) {
            super.init(style: .insetGrouped)
        } else {
            super.init(style: .grouped)
        }

        viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.presentationController?.delegate = self

        self.navigationItem.title = self.viewModel.name

        self.introductionView.textLabel.text = self.viewModel.introduction

        self.submitView.submitButton.setTitle(self.viewModel.submitButtonText, for: .normal)
        self.submitView.submitButton.addTarget(self, action: #selector(submitSurvey), for: .touchUpInside)

        self.thankYouLabel.text = self.viewModel.thankYouMessage
        self.thankYouLabel.adjustsFontForContentSizeCategory = true
        self.thankYouLabel.numberOfLines = 0
        self.thankYouLabel.lineBreakMode = .byWordWrapping
        self.thankYouLabel.font = .preferredFont(forTextStyle: .largeTitle)
        self.thankYouLabel.textAlignment = .center

        if #available(iOS 13.0, *) {
            self.thankYouLabel.textColor = .label
        } else {
            self.thankYouLabel.textColor = .black
        }

        if #available(iOS 13.0, *) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeSurvey))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeSurvey))
        }

        self.tableView.allowsMultipleSelection = true
        self.tableView.keyboardDismissMode = .interactive

        let size = self.introductionView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        self.introductionView.bounds = CGRect(origin: .zero, size: size)

        self.tableView.tableHeaderView = self.introductionView
        self.tableView.tableFooterView = self.submitView
        self.tableView.backgroundView = self.thankYouLabel
        self.tableView.backgroundView?.isHidden = true

        self.tableView.register(SurveyMultiLineCell.self, forCellReuseIdentifier: "multiLine")
        self.tableView.register(SurveySingleLineCell.self, forCellReuseIdentifier: "singleLine")
        self.tableView.register(SurveyChoiceCell.self, forCellReuseIdentifier: "choice")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "unimplemented")

        self.viewModel.launch()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.updateHeaderFooterSize()
        self.tableView.tableHeaderView = self.introductionView
        self.tableView.tableFooterView = self.submitView
    }

    override func viewDidLayoutSubviews() {
        self.updateHeaderFooterSize()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.hasSubmitted ? 0 : self.viewModel.questions.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.viewModel.questions[section] {
        case is SurveyViewModel.FreeformQuestion:
            return 1

        case let choiceQuestion as SurveyViewModel.ChoiceQuestion:
            return choiceQuestion.choiceLabels.count

        case let rangeQuestion as SurveyViewModel.RangeQuestion:
            return rangeQuestion.choiceLabels.count

        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let question = self.viewModel.questions[indexPath.section]

        var reuseIdentifier: String

        switch question {
        case let freeformQuestion as SurveyViewModel.FreeformQuestion:
            reuseIdentifier = freeformQuestion.allowMultipleLines ? "multiLine" : "singleLine"

        case is SurveyViewModel.ChoiceQuestion:
            reuseIdentifier = "choice"

        case is SurveyViewModel.RangeQuestion:
            reuseIdentifier = "choice"

        default:
            reuseIdentifier = "unimplemented"
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.selectionStyle = .none

        switch (question, cell) {
        case (let freeformQuestion as SurveyViewModel.FreeformQuestion, let singleLineCell as SurveySingleLineCell):
            singleLineCell.textField.placeholder = freeformQuestion.placeholderText
            singleLineCell.textField.text = freeformQuestion.answerText
            singleLineCell.textField.delegate = self
            singleLineCell.textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            singleLineCell.textField.tag = self.tag(for: indexPath)
            singleLineCell.textField.accessibilityIdentifier = String(indexPath.section)

        case (let freeformQuestion as SurveyViewModel.FreeformQuestion, let multiLineCell as SurveyMultiLineCell):
            multiLineCell.textView.text = freeformQuestion.answerText
            multiLineCell.textView.delegate = self
            multiLineCell.textView.tag = self.tag(for: indexPath)
            multiLineCell.textView.accessibilityIdentifier = String(indexPath.section)

        case (let choiceQuestion as SurveyViewModel.ChoiceQuestion, let choiceCell):
            choiceCell.textLabel?.text = choiceQuestion.choiceLabels[indexPath.row]

            var imageName: String
            var highlightedImageName: String

            switch choiceQuestion.selectionStyle {
            case .radioButton:
                imageName = "circle"
                highlightedImageName = "smallcircle.fill.circle.fill"
            case .checkbox:
                imageName = "square"
                highlightedImageName = "checkmark.square.fill"
            }

            if #available(iOS 13.0, *) {
                choiceCell.imageView?.image = UIImage(systemName: imageName)
                choiceCell.imageView?.highlightedImage = UIImage(systemName: highlightedImageName)
            } else {
                choiceCell.imageView?.image = UIImage(named: imageName, in: Bundle(for: type(of: self)), compatibleWith: tableView.traitCollection)?.withRenderingMode(.alwaysTemplate)
                choiceCell.imageView?.highlightedImage = UIImage(named: highlightedImageName, in: Bundle(for: type(of: self)), compatibleWith: tableView.traitCollection)?.withRenderingMode(.alwaysTemplate)
            }

        case (let rangeQuestion as SurveyViewModel.RangeQuestion, let choiceCell):
            choiceCell.textLabel?.text = rangeQuestion.choiceLabels[indexPath.row]

            let imageName = "circle"
            let highlightedImageName = "smallcircle.fill.circle.fill"

            if #available(iOS 13.0, *) {
                choiceCell.imageView?.image = UIImage(systemName: imageName)
                choiceCell.imageView?.highlightedImage = UIImage(systemName: highlightedImageName)
            } else {
                choiceCell.imageView?.image = UIImage(named: imageName, in: Bundle(for: type(of: self)), compatibleWith: tableView.traitCollection)?.withRenderingMode(.alwaysTemplate)
                choiceCell.imageView?.highlightedImage = UIImage(named: highlightedImageName, in: Bundle(for: type(of: self)), compatibleWith: tableView.traitCollection)?.withRenderingMode(.alwaysTemplate)
            }

        default:
            cell.textLabel?.text = "Unimplemented"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.viewModel.questions[section].text
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let question = self.viewModel.questions[section]

        return [question.requiredText, question.instructions].compactMap({ $0 }).joined(separator: " — ")
    }

    // MARK: Table View Delegate

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
            return  // Not a choice question
        }

        cell.isSelected = choiceQuestion.selectedChoiceIndexes.contains(indexPath.row)
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {
            return
        }

        if #available(iOS 13.0, *) {
            header.textLabel?.textColor = .label
        } else {
            header.textLabel?.textColor = .black
        }

        header.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        header.textLabel?.text = self.viewModel.questions[section].text
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
            return  // Not a choice question
        }

        choiceQuestion.toggleChoice(at: indexPath.row)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
            return  // Not a choice question
        }

        choiceQuestion.toggleChoice(at: indexPath.row)

        // Override deselection of a radio button
        if choiceQuestion.selectedChoiceIndexes.contains(indexPath.row) {
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
    }

    // MARK: - Survey View Model delgate

    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel) {
        if let _ = self.viewModel.thankYouMessage {
            self.hasSubmitted = true

            self.tableView.deleteSections(IndexSet(integersIn: 0..<self.viewModel.questions.count), with: .top)

            self.thankYouLabel.alpha = 0
            self.thankYouLabel.isHidden = false

            UIView.animate(
                withDuration: 0.1,
                animations: {
                    self.thankYouLabel.alpha = 1
                    self.introductionView.alpha = 0
                    self.submitView.alpha = 0
                },
                completion: { (_) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                        self.dismiss()
                    }
                })
        } else {
            self.dismiss()
        }
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        // TODO: Implement me
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        self.tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
                return  // Not a choice question
            }

            guard let choiceCell = self.tableView.cellForRow(at: indexPath) as? SurveyChoiceCell else {
                return assertionFailure("Should have choice cell for choice question")
            }

            choiceCell.isSelected = choiceQuestion.selectedChoiceIndexes.contains(indexPath.row)
        }
    }

    // MARK: - Targets

    @objc func closeSurvey() {
        self.viewModel.cancel()
        self.dismiss()
    }

    @objc func submitSurvey() {
        self.viewModel.submit()
    }

    @objc func textFieldChanged(_ textField: UITextField) {
        let indexPath = self.indexPath(forTag: textField.tag)

        guard let question = self.viewModel.questions[indexPath.section] as? SurveyViewModel.FreeformQuestion else {
            return assertionFailure("Text field sending events to wrong question")
        }

        question.answerText = textField.text
    }

    // MARK: - Text Field Delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return false
    }

    // MARK: Text View Delegate

    func textViewDidChange(_ textView: UITextView) {
        let indexPath = self.indexPath(forTag: textView.tag)

        guard let question = self.viewModel.questions[indexPath.section] as? SurveyViewModel.FreeformQuestion else {
            return assertionFailure("Text view sending delegate calls to wrong question")
        }

        question.answerText = textView.text
    }

    // MARK: - Adaptive Presentation Controller Delegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.viewModel.cancel()
    }

    // MARK: - Private

    private func updateHeaderFooterSize() {
        let introductionSize = self.introductionView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        self.introductionView.bounds = CGRect(origin: .zero, size: introductionSize)

        let submitSize = self.submitView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        self.submitView.bounds = CGRect(origin: .zero, size: submitSize)

        self.thankYouLabel.frame = self.tableView.readableContentGuide.layoutFrame
    }

    private func indexPath(forTag tag: Int) -> IndexPath {
        return IndexPath(row: tag & 0xFFFF, section: tag >> 16)
    }

    private func tag(for indexPath: IndexPath) -> Int {
        return (indexPath.section << 16) | (indexPath.item & 0xFFFF)
    }

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
