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

    enum FooterMode {
        case submitButton
        case thankYou
        case validationError
    }

    var footerMode: FooterMode = .submitButton {
        didSet {
            var viewToHide: UIView?
            var viewToShow: UIView?

            switch self.footerMode {
            case .submitButton:
                viewToShow = self.submitView.submitButton
                viewToHide = self.submitView.submitLabel

            case .thankYou:
                self.submitView.submitLabel.text = self.viewModel.thankYouMessage
                self.submitView.submitLabel.textColor = self.normalColor
                viewToShow = self.submitView.submitLabel
                viewToHide = self.submitView.submitButton

            case .validationError:
                self.submitView.submitLabel.text = self.viewModel.validationErrorMessage
                self.submitView.submitLabel.textColor = self.errorColor
                viewToShow = self.submitView.submitLabel
                viewToHide = self.submitView.submitButton
            }

            UIView.transition(
                with: self.submitView, duration: 0.25, options: .transitionCrossDissolve) {
                viewToHide?.isHidden = true
                viewToShow?.isHidden = false
            }
        }
    }

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel
        self.introductionView = SurveyIntroductionView(frame: .zero)
        self.submitView = SurveySubmitView(frame: .zero)

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

        if #available(iOS 13.0, *) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeSurvey))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeSurvey))
        }

        self.tableView.allowsMultipleSelection = true
        self.tableView.keyboardDismissMode = .interactive

        self.tableView.tableHeaderView = self.introductionView
        self.tableView.tableFooterView = self.submitView

        self.tableView.register(SurveyMultiLineCell.self, forCellReuseIdentifier: "multiLine")
        self.tableView.register(SurveySingleLineCell.self, forCellReuseIdentifier: "singleLine")
        self.tableView.register(SurveyChoiceCell.self, forCellReuseIdentifier: "choice")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "unimplemented")

        self.tableView.register(SurveyQuestionHeaderView.self, forHeaderFooterViewReuseIdentifier: "question")

        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.estimatedSectionHeaderHeight = 66.0

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
        return self.viewModel.questions.count
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
            multiLineCell.placeholderLabel.text = freeformQuestion.placeholderText
            multiLineCell.placeholderLabel.isHidden = !(freeformQuestion.answerText?.isEmpty ?? true)
            multiLineCell.textView.delegate = self
            multiLineCell.textView.tag = self.tag(for: indexPath)
            multiLineCell.textView.accessibilityIdentifier = String(indexPath.section)

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

            if indexPath.row == 0 {
                choiceCell.detailTextLabel?.text = rangeQuestion.minText
            } else if indexPath.row == rangeQuestion.choiceLabels.count - 1 {
                choiceCell.detailTextLabel?.text = rangeQuestion.maxText
            } else {
                choiceCell.detailTextLabel?.text = nil
            }

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

        default:
            cell.textLabel?.text = "Unimplemented"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let question = self.viewModel.questions[section]

        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "question") as? SurveyQuestionHeaderView else {
            assertionFailure("Unexpected header view registered for identifier `question`.")
            return nil
        }

        let instructionsText = [question.requiredText, question.instructions].compactMap({ $0 }).joined(separator: " — ")

        header.questionLabel.text = question.text
        header.instructionsLabel.text = instructionsText
        header.instructionsLabel.isHidden = instructionsText.isEmpty

        header.questionLabel.textColor = question.isMarkedAsInvalid ? self.errorColor : self.normalColor
        header.instructionsLabel.textColor = question.isMarkedAsInvalid ? self.errorColor : self.normalColor

        return header
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let question = self.viewModel.questions[section]

        return question.isMarkedAsInvalid ? question.errorMessage : nil
    }

    // MARK: Table View Delegate

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
            return  // Not a choice question
        }

        cell.isSelected = choiceQuestion.selectedChoiceIndexes.contains(indexPath.row)
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

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let footerView = view as? UITableViewHeaderFooterView else {
            return
        }

        footerView.textLabel?.alpha = 1  // We may have faded this out in `surveyViewModelValidationDidChange(_:)`.
        footerView.textLabel?.textColor = self.errorColor  // Footers always display an error in the error color.
    }

    // MARK: - Survey View Model delgate

    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel) {
        if let _ = self.viewModel.thankYouMessage {
            self.footerMode = .thankYou

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
                self.dismiss()
            }
        } else {
            self.dismiss()
        }
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        self.footerMode = viewModel.isMarkedAsInvalid ? .validationError : .submitButton

        self.tableView.beginUpdates()  // Animate in/out any error message footers

        var visibleSectionIndexes = tableView.indexPathsForVisibleRows?.map { $0.section } ?? []

        // There might be a header view for a subsequent section whose top row isn't visible.
        if let lastVisibleSectionIndex = visibleSectionIndexes.last, lastVisibleSectionIndex < self.tableView.numberOfSections - 1 {
            visibleSectionIndexes.append(lastVisibleSectionIndex + 1)
        }

        // There might be a footer view for a previous section whose bottom row isn't visible.
        if let firstVisibleSectionIndex = visibleSectionIndexes.first, firstVisibleSectionIndex >= 1 {
            visibleSectionIndexes.append(firstVisibleSectionIndex - 1)
        }

        visibleSectionIndexes.forEach({ sectionIndex in
            let question = viewModel.questions[sectionIndex]

            if let header = self.tableView.headerView(forSection: sectionIndex) as? SurveyQuestionHeaderView {
                UIView.transition(
                    with: header, duration: 0.25, options: .transitionCrossDissolve) {
                        header.questionLabel.textColor = question.isMarkedAsInvalid ? self.errorColor : self.normalColor
                        header.instructionsLabel.textColor = question.isMarkedAsInvalid ? self.errorColor : self.normalColor
                    }
            }

            // The footer's position animates properly when a question is un-marked,
            // but the text stays visible for some reason (a UIKit bug?).
            if let footer = self.tableView.footerView(forSection: sectionIndex) {
                UIView.animate(withDuration: 0.25) {
                    footer.textLabel?.alpha = question.isMarkedAsInvalid ? 1 : 0
                }
            }
        })

        self.tableView.endUpdates()
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        self.tableView.indexPathsForVisibleRows?.forEach { indexPath in
            guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
                return  // Not a choice question
            }

            guard let cell = self.tableView.cellForRow(at: indexPath) else {
                return  // Cell may already be offscreen
            }

            guard let choiceCell = cell as? SurveyChoiceCell else {
                return assertionFailure("Should have choice cell for choice question")
            }

            choiceCell.isSelected = choiceQuestion.selectedChoiceIndexes.contains(indexPath.row)
        }
    }

    // MARK: - Targets

    @objc func closeSurvey() {
        if self.viewModel.hasAnswer {
            self.confirmCancel()
        } else {
            self.cancel()
        }
    }

    @objc func submitSurvey() {
        self.viewModel.submit()

        if !self.viewModel.isValid {
            self.scrollToFirstInvalidQuestion()
        }
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

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if self.viewModel.hasAnswer {
            self.confirmCancel()
            return false
        } else {
            return true
        }
    }

    // MARK: - Private

    private func updateHeaderFooterSize() {
        let introductionSize = self.introductionView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        self.introductionView.bounds = CGRect(origin: .zero, size: introductionSize)

        let submitSize = self.submitView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

        self.submitView.bounds = CGRect(origin: .zero, size: submitSize)
    }

    private func indexPath(forTag tag: Int) -> IndexPath {
        return IndexPath(row: tag & 0xFFFF, section: tag >> 16)
    }

    private func tag(for indexPath: IndexPath) -> Int {
        return (indexPath.section << 16) | (indexPath.item & 0xFFFF)
    }

    private func confirmCancel() {
        let alertController = UIAlertController(title: "Are you sure you want to close this survey?", message: "You will lose any responses you have entered.", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Close Survey", style: .destructive, handler: { _ in self.cancel() }))
        alertController.addAction(UIAlertAction(title: "Continue Responding", style: .cancel, handler: nil))

        self.present(alertController, animated: true, completion: nil)
    }

    private func cancel() {
        self.viewModel.cancel()
        self.dismiss()
    }

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func scrollToFirstInvalidQuestion() {
        if let firstInvalidQuestionIndex = self.viewModel.invalidQuestionIndexes.first {
            self.tableView.scrollToRow(at: IndexPath(row: 0, section: firstInvalidQuestionIndex), at: .middle, animated: true)
        }
    }

    private var normalColor: UIColor {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }

    private var errorColor: UIColor {
        return .systemRed
    }
}
