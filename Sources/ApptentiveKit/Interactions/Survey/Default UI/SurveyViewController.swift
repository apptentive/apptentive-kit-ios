//
//  SurveyViewController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyViewController: UITableViewController, UITextFieldDelegate, UITextViewDelegate, SurveyViewModelDelegate, UIAdaptivePresentationControllerDelegate {
    static let animationDuration = 0.30

    static let minLabelAttrbutes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1
        paragraphStyle.alignment = .left

        return [.paragraphStyle: paragraphStyle]
    }()

    static let maxLabelAttrbutes: [NSAttributedString.Key: Any] = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.hyphenationFactor = 1
        paragraphStyle.alignment = .right

        return [.paragraphStyle: paragraphStyle]
    }()

    let viewModel: SurveyViewModel
    let introductionView: SurveyIntroductionView?
    let submitView: SurveySubmitView?
    let surveyBranchedBottomView: SurveyBranchedContainerBottomView?
    let backgroundView: SurveyBackgroundView?

    var firstResponderIndexPath: IndexPath? {
        didSet {
            if let indexPath = self.firstResponderIndexPath {
                self.firstResponderCell = self.tableView.cellForRow(at: indexPath)
            } else {
                self.firstResponderCell = nil
            }
        }
    }

    override var inputAccessoryView: UIView? {
        switch self.viewModel.displayMode {
        case .list:
            return nil

        case .paged:
            return self.surveyBranchedBottomView
        }
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    var firstResponderCell: UITableViewCell?

    enum FooterMode {
        case submitButton
        case thankYou
        case validationError
        case next
    }

    var footerMode: FooterMode = .submitButton {
        didSet {
            var viewToHide: UIView?
            var viewToShow: UIView?

            switch self.footerMode {
            case .submitButton:
                viewToShow = self.submitView?.submitButton
                viewToHide = self.submitView?.submitLabel

            case .thankYou:
                self.submitView?.submitLabel.text = self.viewModel.thankYouMessage
                self.submitView?.submitLabel.textColor = .apptentiveSubmitStatusLabel
                viewToShow = self.submitView?.submitLabel

            case .validationError:

                self.submitView?.submitLabel.text = self.viewModel.validationErrorMessage
                self.submitView?.submitLabel.textColor = .apptentiveError
                viewToShow = self.submitView?.submitLabel

            case .next:
                viewToShow = self.submitView?.submitButton
                viewToHide = self.submitView?.submitLabel
            }

            if let submitView = submitView {
                UIView.transition(

                    with: submitView, duration: 0.33, options: .transitionCrossDissolve
                ) {
                    viewToHide?.isHidden = true
                    viewToShow?.isHidden = false
                }
            }
        }
    }

    var pagedSurveyBottomScaledHeight: CGFloat {
        let fontMetrics: UIFontMetrics = UIFontMetrics(forTextStyle: .headline)
        return fontMetrics.scaledValue(for: 160)
    }

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel
        self.backgroundView = SurveyBackgroundView(frame: .zero)

        switch viewModel.displayMode {
        case .list:
            self.introductionView = SurveyIntroductionView(frame: .zero)
            self.submitView = SurveySubmitView(frame: .zero)
            self.surveyBranchedBottomView = nil

        case .paged:
            self.introductionView = nil
            self.submitView = nil

            self.surveyBranchedBottomView = SurveyBranchedContainerBottomView(frame: .zero, numberOfSegments: viewModel.pageIndicatorSegmentCount)
        }

        super.init(style: .apptentive)
        self.surveyBranchedBottomView?.frame = CGRect(x: 0, y: 0, width: 320, height: self.pagedSurveyBottomScaledHeight)
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.introductionView?.textLabel.text = self.viewModel.introduction

        if let headerLogo = UIImage.apptentiveHeaderLogo {
            let headerImageView = UIImageView(image: headerLogo.withRenderingMode(.alwaysOriginal))
            headerImageView.contentMode = .scaleAspectFit
            self.navigationItem.titleView = headerImageView
        } else {
            self.navigationItem.title = self.viewModel.name
        }

        switch self.viewModel.displayMode {
        case .list:
            self.submitView?.submitButton.setTitle(self.viewModel.advanceButtonText, for: .normal)
            self.submitView?.disclaimerLabel.text = self.viewModel.disclaimerText

            self.submitView?.submitButton.addTarget(self, action: #selector(submitSurvey), for: .touchUpInside)

            // Pre-set submit label to allocate space
            self.submitView?.submitLabel.text = self.viewModel.thankYouMessage ?? self.viewModel.validationErrorMessage

            self.introductionView?.textLabel.text = self.viewModel.introduction

            self.configureTermsOfService()

        case .paged:
            self.footerMode = .next

            if let termsText = self.viewModel.termsAndConditions?.linkLabel {
                let attributedTermsAndConditions = NSMutableAttributedString(string: termsText)
                attributedTermsAndConditions.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: termsText.count))
                self.surveyBranchedBottomView?.bottomView.termsAndConditions.setAttributedTitle(attributedTermsAndConditions, for: .normal)
                self.configureTermsOfService()
            } else {
                switch UIToolbar.apptentiveMode {
                case .alwaysShown:
                    self.surveyBranchedBottomView?.bottomView.backgroundColor = .apptentiveSubmitButton
                    self.surveyBranchedBottomView?.backgroundColor = .apptentiveSubmitButton
                case .hiddenWhenEmpty:
                    self.surveyBranchedBottomView?.bottomView.backgroundColor = .apptentiveGroupedBackground
                    self.surveyBranchedBottomView?.backgroundColor = .apptentiveGroupedBackground
                }
            }
            self.surveyBranchedBottomView?.bottomView.nextButton.setTitle(self.viewModel.advanceButtonText, for: .normal)
            self.surveyBranchedBottomView?.bottomView.nextButton.addTarget(self, action: #selector(submitSurvey), for: .touchUpInside)

            self.backgroundView?.label.text = self.viewModel.introduction
            self.backgroundView?.disclaimerLabel.text = self.viewModel.disclaimerText
            if self.viewModel.highlightFirstQuestionSegment {
                self.surveyBranchedBottomView?.bottomView.surveyIndicator.updateSelectedSegmentAppearance()
            }
        }

        self.navigationController?.presentationController?.delegate = self

        if !ApptentiveNavigationController.prefersLargeHeader {
            self.navigationItem.rightBarButtonItem = .apptentiveClose
            self.navigationItem.rightBarButtonItem?.target = self
            self.navigationItem.rightBarButtonItem?.action = #selector(cancelSurvey)
        }

        // Pre-set submit label to allocate space
        self.submitView?.submitLabel.text = self.viewModel.thankYouMessage ?? self.viewModel.validationErrorMessage
        self.tableView.backgroundColor = .apptentiveGroupedBackground
        self.tableView.backgroundView = self.backgroundView
        self.tableView.separatorColor = .apptentiveSeparator

        self.tableView.allowsMultipleSelection = true
        self.tableView.keyboardDismissMode = .interactive

        self.tableView.tableHeaderView = self.introductionView
        self.tableView.tableFooterView = self.submitView

        self.tableView.register(SurveyMultiLineCell.self, forCellReuseIdentifier: "multiLine")
        self.tableView.register(SurveySingleLineCell.self, forCellReuseIdentifier: "singleLine")
        self.tableView.register(SurveyChoiceCell.self, forCellReuseIdentifier: "choice")
        self.tableView.register(SurveyOtherChoiceCell.self, forCellReuseIdentifier: "otherChoice")
        self.tableView.register(SurveyRangeCell.self, forCellReuseIdentifier: "rangeControl")
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "unimplemented")

        self.tableView.register(SurveyQuestionHeaderView.self, forHeaderFooterViewReuseIdentifier: "question")
        self.tableView.register(SurveyQuestionFooterView.self, forHeaderFooterViewReuseIdentifier: "questionFooter")

        self.tableView.sectionHeaderHeight = UITableView.automaticDimension
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedSectionHeaderHeight = 75.0
        self.tableView.estimatedSectionFooterHeight = 35.0
        self.tableView.estimatedRowHeight = 44.0
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateHeaderFooterSize()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //We can't capture the view's window in the viewDidLoad, which is needed when sizing the larger header.
        ApptentiveNavigationController.prefersLargeHeader ? self.configureNavigationBarForLargeHeader() : self.configureNavigationBar()
        // Need to increase the inset becuase when large dynamic type is set, the bottom input accessory view gets a larger height which covers the view.
        if self.traitCollection.preferredContentSizeCategory >= .extraLarge && self.viewModel.displayMode == .paged {
            self.navigationController?.additionalSafeAreaInsets.bottom = self.pagedSurveyBottomScaledHeight
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.updateHeaderFooterSize()
        self.tableView.tableHeaderView = self.introductionView
        self.tableView.tableFooterView = self.submitView
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
            return choiceQuestion.choices.count

        case is SurveyViewModel.RangeQuestion:
            return 1

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

        case let choiceQuestion as SurveyViewModel.ChoiceQuestion:
            let choice = choiceQuestion.choices[indexPath.row]
            if choice.supportsOther {
                reuseIdentifier = "otherChoice"
            } else {
                reuseIdentifier = "choice"
            }

        case is SurveyViewModel.RangeQuestion:
            reuseIdentifier = "rangeControl"

        default:
            reuseIdentifier = "unimplemented"
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.selectionStyle = .none

        switch (question, cell) {
        case (let freeformQuestion as SurveyViewModel.FreeformQuestion, let singleLineCell as SurveySingleLineCell):
            singleLineCell.textField.attributedPlaceholder = NSAttributedString(
                string: freeformQuestion.placeholderText ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.apptentiveTextInputPlaceholder, NSAttributedString.Key.font: UIFont.apptentiveTextInputPlaceholder])
            singleLineCell.textField.text = freeformQuestion.value
            singleLineCell.textField.delegate = self
            singleLineCell.textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
            singleLineCell.textField.tag = self.tag(for: indexPath)
            singleLineCell.textField.accessibilityIdentifier = String(indexPath.section)

            singleLineCell.tableViewStyle = tableView.style
            singleLineCell.isMarkedAsInvalid = question.isMarkedAsInvalid

        case (let freeformQuestion as SurveyViewModel.FreeformQuestion, let multiLineCell as SurveyMultiLineCell):
            multiLineCell.textView.text = freeformQuestion.value
            multiLineCell.placeholderLabel.text = freeformQuestion.placeholderText
            multiLineCell.placeholderLabel.isHidden = !(freeformQuestion.value?.isEmpty ?? true)
            multiLineCell.textView.delegate = self
            multiLineCell.textView.tag = self.tag(for: indexPath)
            multiLineCell.textView.accessibilityIdentifier = String(indexPath.section)
            multiLineCell.textView.accessibilityLabel = freeformQuestion.placeholderText
            multiLineCell.tableViewStyle = tableView.style
            multiLineCell.isMarkedAsInvalid = question.isMarkedAsInvalid

        case (let rangeQuestion as SurveyViewModel.RangeQuestion, let rangeChoiceCell as SurveyRangeCell):
            rangeChoiceCell.choiceLabels = rangeQuestion.choiceLabels

            guard let segmentedControl = rangeChoiceCell.segmentedControl else {
                apptentiveCriticalError("Expected range cell to have segmented control.")
                break
            }

            segmentedControl.addTarget(self, action: #selector(rangeControlValueDidChange(_:)), for: .valueChanged)
            segmentedControl.tag = self.tag(for: indexPath)
            for (index, subview) in segmentedControl.subviews.enumerated() {
                let segmentLabel = segmentedControl.titleForSegment(at: index)
                subview.accessibilityLabel = segmentLabel
                subview.accessibilityHint = rangeQuestion.accessibilityHintForSegment
                subview.accessibilityTraits = .none
            }

            if let selectedIndex = rangeQuestion.selectedValueIndex {
                segmentedControl.selectedSegmentIndex = selectedIndex
            } else {
                segmentedControl.selectedSegmentIndex = UISegmentedControl.noSegment
            }

            rangeChoiceCell.minLabel.attributedText = rangeQuestion.minText.flatMap { NSAttributedString(string: $0, attributes: Self.minLabelAttrbutes) }
            rangeChoiceCell.maxLabel.attributedText = rangeQuestion.maxText.flatMap { NSAttributedString(string: $0, attributes: Self.maxLabelAttrbutes) }

        case (let choiceQuestion as SurveyViewModel.ChoiceQuestion, let choiceCell as SurveyChoiceCell):
            let choice = choiceQuestion.choices[indexPath.row]

            choiceCell.choiceLabel.text = choice.label
            choiceCell.accessibilityLabel = choice.label
            switch choiceQuestion.selectionStyle {
            case .radioButton:
                choiceCell.buttonImageView.image = .apptentiveRadioButton
                choiceCell.buttonImageView.highlightedImage = .apptentiveRadioButtonSelected
            case .checkbox:
                choiceCell.buttonImageView.image = .apptentiveCheckbox
                choiceCell.buttonImageView.highlightedImage = .apptentiveCheckboxSelected
            }

            if let otherCell = choiceCell as? SurveyOtherChoiceCell {
                otherCell.isExpanded = choice.isSelected
                otherCell.isMarkedAsInvalid = choice.isMarkedAsInvalid
                otherCell.textField.text = choice.value
                otherCell.textField.delegate = self
                otherCell.textField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
                otherCell.textField.tag = self.tag(for: indexPath)
                otherCell.textField.attributedPlaceholder = NSAttributedString(string: choice.placeholderText ?? "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.apptentiveTextInputPlaceholder])
            }

        default:
            cell.textLabel?.text = "Unimplemented"
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let question = self.viewModel.questions[section]

        guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "question") as? SurveyQuestionHeaderView else {
            apptentiveCriticalError("Unexpected header view registered for identifier `question`.")
            return nil
        }

        let instructionsText = [question.requiredText, question.instructions].compactMap({ $0 }).joined(separator: " — ")

        header.questionLabel.text = question.text
        header.instructionsLabel.text = instructionsText
        header.instructionsLabel.isHidden = instructionsText.isEmpty
        header.questionLabel.textColor = question.isMarkedAsInvalid ? .apptentiveError : .apptentiveQuestionLabel
        header.instructionsLabel.textColor = question.isMarkedAsInvalid ? .apptentiveError : .apptentiveInstructionsLabel

        header.contentView.accessibilityTraits = .header
        header.contentView.accessibilityLabel = question.accessibilityLabel
        header.contentView.isAccessibilityElement = true

        return header
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: "questionFooter") as? SurveyQuestionFooterView else {
            apptentiveCriticalError("Unexpected footer view registered for identifier `question`.")
            return nil
        }

        let question = self.viewModel.questions[section]

        footer.errorLabel.text = question.isMarkedAsInvalid ? question.errorMessage : nil
        footer.errorLabel.textColor = .apptentiveError

        return footer
    }

    // MARK: Table View Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
            return  // Not a choice question
        }

        choiceQuestion.toggleChoice(at: indexPath.row)

        // Automatically focus text field in "Other" choice cells.
        if choiceQuestion.choices[indexPath.row].supportsOther {
            guard let otherCell = tableView.cellForRow(at: indexPath) as? SurveyOtherChoiceCell else {
                return apptentiveCriticalError("Expected other cell for other choice")
            }

            otherCell.textField.becomeFirstResponder()

            // Animation seems to be needed to avoid choiceLabel jumping when expanding.
            UIView.animate(withDuration: SurveyViewController.animationDuration) {
                otherCell.isExpanded = true
                otherCell.layoutIfNeeded()
            }

            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
            return  // Not a choice question
        }

        choiceQuestion.toggleChoice(at: indexPath.row)
        let choice = choiceQuestion.choices[indexPath.row]

        // Override deselection of a radio button

        if choice.isSelected {
            self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else if choice.supportsOther {
            // Automatically unfocus text field in "Other" choice cells (assuming not a radio button).
            guard let otherCell = tableView.cellForRow(at: indexPath) as? SurveyOtherChoiceCell else {
                return apptentiveCriticalError("Expected other cell for other choice")
            }

            otherCell.textField.resignFirstResponder()

            UIView.animate(withDuration: SurveyViewController.animationDuration) {
                otherCell.isExpanded = false
                otherCell.layoutIfNeeded()
            }

            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if let firstInvalidQuestionIndex = self.viewModel.invalidQuestionIndexes.min() {
            UIAccessibility.post(notification: .layoutChanged, argument: self.tableView.headerView(forSection: firstInvalidQuestionIndex))
        }
    }

    // MARK: - Survey View Model Delegate

    func surveyViewModelPageWillChange(_ viewModel: SurveyViewModel) {
        let firstResponder: UIResponder? = {
            switch self.firstResponderCell {
            case let singleLineCell as SurveySingleLineCell:
                return singleLineCell.textField

            case let multiLineCell as SurveyMultiLineCell:
                return multiLineCell.textView

            case let otherChoiceCell as SurveyOtherChoiceCell:
                return otherChoiceCell.textField

            case .none:
                return nil

            default:
                apptentiveCriticalError("Non-null first responder cell was of unknown type.")
                return nil
            }
        }()

        firstResponder?.resignFirstResponder()
        self.firstResponderCell = nil
        self.firstResponderIndexPath = nil
    }

    func surveyViewModelPageDidChange(_ viewModel: SurveyViewModel) {
        self.backgroundView?.disclaimerLabel.isHidden = true
        let oldSectionCount = self.tableView.numberOfSections
        let newSectionCount = viewModel.questions.count

        // Reload sections that are populated in both old and new page
        if oldSectionCount > 0 && newSectionCount > 0 {
            let sectionsToReload = IndexSet(0..<min(oldSectionCount, newSectionCount))
            self.tableView.reloadSections(sectionsToReload, with: .left)
        }

        // Adjust number of sections if needed
        if newSectionCount > oldSectionCount {
            let sectionsToInsert = IndexSet(oldSectionCount..<newSectionCount)
            self.tableView.insertSections(sectionsToInsert, with: .right)
        } else if newSectionCount < oldSectionCount {
            let sectionsToDelete = IndexSet(newSectionCount..<oldSectionCount)
            self.tableView.deleteSections(sectionsToDelete, with: .left)
        }

        self.backgroundView?.label.text = viewModel.introduction
        self.surveyBranchedBottomView?.bottomView.nextButton.setTitle(viewModel.advanceButtonText, for: .normal)

        if self.viewModel.surveyDidSendResponse {
            self.navigationItem.rightBarButtonItem = .none
            self.surveyBranchedBottomView?.bottomView.surveyIndicator.updateSurveyIndicatorForThankYouScreen()
            self.backgroundView?.disclaimerLabel.isHidden = false
        } else if let selectedSegmentIndex = self.viewModel.currentSelectedSegmentIndex {
            self.surveyBranchedBottomView?.bottomView.surveyIndicator.currentSelectedSetIndex = selectedSegmentIndex

            UIAccessibility.post(notification: .screenChanged, argument: self.tableView.headerView(forSection: 0))
        }
    }

    func surveyViewModelDidFinish(_ viewModel: SurveyViewModel) {
        if let _ = self.viewModel.thankYouMessage {
            self.footerMode = .thankYou

            if let submitView = self.submitView {
                UIAccessibility.post(notification: .screenChanged, argument: submitView.submitLabel)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
                self.dismiss()
            }
        } else {
            self.dismiss()
        }
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        self.footerMode = viewModel.isMarkedAsInvalid ? .validationError : .submitButton

        // Disregard first responder changes for the duration of the update.
        self.isUpdatingValidation = true

        self.tableView.beginUpdates()

        // Reload sections whose headers or footers might be visible.
        let sectionsBeingReloaded = self.sectionIndexesWithPotentiallyVisibleHeadersOrFooters
        self.tableView.reloadSections(sectionsBeingReloaded, with: .fade)

        self.tableView.endUpdates()

        // Restore selection and first responder status for reloaded rows.
        for sectionIndex in sectionsBeingReloaded {
            if let choiceQuestion = self.viewModel.questions[sectionIndex] as? SurveyViewModel.ChoiceQuestion {
                for (choiceIndex, choice) in choiceQuestion.choices.enumerated() {
                    if choice.isSelected {
                        tableView.selectRow(at: IndexPath(row: choiceIndex, section: sectionIndex), animated: false, scrollPosition: .none)
                    }
                }
            }

            if let firstResponderIndexPath = self.firstResponderIndexPath, sectionIndex == firstResponderIndexPath.section {
                switch self.tableView.cellForRow(at: firstResponderIndexPath) {
                case let singleLineCell as SurveySingleLineCell:
                    singleLineCell.textField.becomeFirstResponder()

                case let multiLineCell as SurveyMultiLineCell:
                    multiLineCell.textView.becomeFirstResponder()

                case let otherChoiceCell as SurveyOtherChoiceCell:
                    otherChoiceCell.textField.becomeFirstResponder()

                default:
                    break
                }
            }
        }

        self.isUpdatingValidation = false
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        for indexPath in self.tableView.indexPathsForVisibleRows ?? [] {
            guard let choiceQuestion = self.viewModel.questions[indexPath.section] as? SurveyViewModel.ChoiceQuestion else {
                continue  // Not a choice question
            }

            guard let cell = self.tableView.cellForRow(at: indexPath) else {
                continue  // Cell may already be offscreen
            }

            let isSelected = choiceQuestion.choices[indexPath.row].isSelected

            if isSelected && !cell.isSelected {
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            } else if !isSelected && cell.isSelected {
                self.tableView.deselectRow(at: indexPath, animated: true)

                if let otherCell = tableView.cellForRow(at: indexPath) as? SurveyOtherChoiceCell {
                    otherCell.textField.resignFirstResponder()

                    self.tableView.beginUpdates()
                    otherCell.isExpanded = false
                    self.tableView.endUpdates()
                }
            }
        }
    }

    // MARK: - Targets

    @objc func keyboardWillAppear() {
        if let bottomView = surveyBranchedBottomView {
            bottomView.bottomView.stackViewHeightConstraint.constant = 80
            bottomView.bottomView.backgroundColor = .white
            UIView.transition(

                with: bottomView, duration: 0.10, options: .transitionCrossDissolve
            ) {
                bottomView.bottomView.termsAndConditions.isHidden = true
                bottomView.bottomView.setNeedsLayout()
            }
        }
    }

    @objc func keyboardWillDisappear() {
        if let bottomView = surveyBranchedBottomView {
            bottomView.bottomView.stackViewHeightConstraint.constant = 160
            bottomView.bottomView.backgroundColor = .apptentiveSubmitButton
            UIView.transition(

                with: bottomView, duration: 0.10, options: .transitionCrossDissolve
            ) {
                bottomView.bottomView.termsAndConditions.isHidden = false
                bottomView.bottomView.setNeedsLayout()
            }
        }
    }

    @objc func cancelSurvey() {
        if self.viewModel.shouldConfirmCancel {
            self.confirmCancel()
        } else {
            self.cancel()
        }
    }

    @objc func openTermsAndConditions() {
        self.viewModel.openTermsAndConditions()
    }

    @objc func submitSurvey() {
        self.viewModel.advance()

        if !self.viewModel.isValid {
            self.scrollToFirstInvalidQuestion()
        }
    }

    @objc func textFieldChanged(_ textField: UITextField) {
        self.viewModel.setValue(textField.text, for: self.indexPath(forTag: textField.tag))
    }

    @objc func rangeControlValueDidChange(_ segmentedControl: UISegmentedControl) {
        var indexPath = self.indexPath(forTag: segmentedControl.tag)
        indexPath.row = segmentedControl.selectedSegmentIndex

        self.viewModel.selectValueFromRange(at: indexPath)
    }

    // MARK: - Text Field Delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard !self.isUpdatingValidation else {
            return
        }

        if self.viewModel.displayMode == .paged {
            self.keyboardWillAppear()
        }

        self.firstResponderIndexPath = self.indexPath(forTag: textField.tag)
        textField.layer.borderColor = UIColor.apptentiveTextInputBorderSelected.cgColor
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard !self.isUpdatingValidation else {
            return
        }

        if self.viewModel.displayMode == .paged {
            self.keyboardWillDisappear()
        }

        self.firstResponderIndexPath = nil
        textField.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
    }

    // MARK: Text View Delegate

    func textViewDidChange(_ textView: UITextView) {
        self.viewModel.setValue(textView.text, for: self.indexPath(forTag: textView.tag))
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        guard !self.isUpdatingValidation else {
            return
        }

        self.firstResponderIndexPath = self.indexPath(forTag: textView.tag)
        textView.layer.borderColor = UIColor.apptentiveTextInputBorderSelected.cgColor
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        guard !self.isUpdatingValidation else {
            return
        }

        self.firstResponderIndexPath = nil
        textView.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
    }

    // MARK: - Adaptive Presentation Controller Delegate

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.viewModel.cancel(partial: false)
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        if self.viewModel.shouldConfirmCancel {
            DispatchQueue.main.async {
                self.confirmCancel()
            }
            return false
        } else {
            return true
        }
    }

    // MARK: - Private

    private var isUpdatingValidation = false

    private var sectionIndexesWithPotentiallyVisibleHeadersOrFooters: IndexSet {
        var result = tableView.indexPathsForVisibleRows?.map { $0.section } ?? []

        // There might be a header view for a subsequent section whose top row isn't visible.
        if let lastVisibleSectionIndex = result.last, lastVisibleSectionIndex < self.tableView.numberOfSections - 1 {
            result.append(lastVisibleSectionIndex + 1)
        }

        // There might be a footer view for a previous section whose bottom row isn't visible.
        if let firstVisibleSectionIndex = result.first, firstVisibleSectionIndex >= 1 {
            result.append(firstVisibleSectionIndex - 1)
        }

        return IndexSet(result)
    }

    private func updateHeaderFooterSize() {
        if let introductionView = self.introductionView {
            let introductionSize = introductionView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

            introductionView.bounds = CGRect(origin: .zero, size: introductionSize)
        }

        if let submitView = self.submitView {
            let submitSize = submitView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

            submitView.bounds = CGRect(origin: .zero, size: submitSize)
        }
    }

    private func indexPath(forTag tag: Int) -> IndexPath {
        return IndexPath(row: tag & 0xFFFF, section: tag >> 16)
    }

    private func tag(for indexPath: IndexPath) -> Int {
        return (indexPath.section << 16) | (indexPath.item & 0xFFFF)
    }

    private func configureTermsOfService() {
        if let termsText = self.viewModel.termsAndConditions?.linkLabel {
            if let bottomView = self.surveyBranchedBottomView, self.viewModel.displayMode == .paged {
                bottomView.bottomView.termsAndConditions.addTarget(self, action: #selector(openTermsAndConditions), for: .touchUpInside)
            } else if let navigationController = self.navigationController {
                navigationController.setToolbarHidden(false, animated: true)

                let horizontalInset = (navigationController.toolbar.bounds.width - navigationController.toolbar.readableContentGuide.layoutFrame.width) / 2

                let button = UIButton()
                button.setAttributedTitle(.init(string: termsText, attributes: [.underlineStyle: 1]), for: .normal)
                button.titleLabel?.numberOfLines = 0
                button.titleLabel?.font = .apptentiveTermsOfServiceLabel
                button.titleLabel?.textColor = .apptentiveTermsOfServiceLabel
                button.titleLabel?.textAlignment = .center
                button.titleEdgeInsets = .init(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset)

                button.addTarget(self, action: #selector(openTermsAndConditions), for: .touchUpInside)

                let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

                let barButtonItem = UIBarButtonItem.init(customView: button)

                self.setToolbarItems([flexible, barButtonItem, flexible], animated: false)
            }
        } else {
            self.navigationController?.setToolbarHidden((UIToolbar.apptentiveMode == .hiddenWhenEmpty), animated: true)
        }
    }

    private func confirmCancel() {
        let alertController = UIAlertController(title: self.viewModel.closeConfirmation.title, message: self.viewModel.closeConfirmation.message, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(
                title: self.viewModel.closeConfirmation.closeButtonTitle, style: .destructive,
                handler: { _ in
                    self.cancel(partial: true)

                }))
        alertController.addAction(
            UIAlertAction(
                title: self.viewModel.closeConfirmation.continueButtonTitle, style: .cancel,
                handler: { _ in
                    self.viewModel.continuePartial()
                }))

        alertController.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem

        self.present(alertController, animated: true, completion: nil)
    }

    private func configureNavigationBarForLargeHeader() {
        if let navigationControllerView = self.navigationController?.view {
            //Increase top bar height.
            var topBarHeight: CGFloat = 0
            if #available(iOS 13.0, *) {
                if let windowScene = self.view.window?.windowScene {
                    topBarHeight = windowScene.screen.bounds.width / 3
                }
            } else {
                topBarHeight = UIScreen.main.bounds.width / 3
            }

            self.navigationController?.additionalSafeAreaInsets.top = topBarHeight

            //Place the header logo if added and center it.
            if let headerLogo = UIImage.apptentiveHeaderLogo {
                let headerImageView = UIImageView(image: headerLogo.withRenderingMode(.alwaysOriginal))
                headerImageView.contentMode = .scaleAspectFit
                navigationControllerView.addSubview(headerImageView)
                headerImageView.translatesAutoresizingMaskIntoConstraints = false

                NSLayoutConstraint.activate([
                    headerImageView.topAnchor.constraint(equalTo: navigationControllerView.topAnchor, constant: topBarHeight / 1.5),
                    headerImageView.leadingAnchor.constraint(equalTo: navigationControllerView.leadingAnchor, constant: 100),
                    headerImageView.trailingAnchor.constraint(equalTo: navigationControllerView.trailingAnchor, constant: -100),
                ])
            }

            //Configure the close button.
            if #available(iOS 13.0, *) {
                UIButton.apptentiveClose?.setPreferredSymbolConfiguration(.init(pointSize: 20.0), forImageIn: .normal)
            }
            if let closeButton = UIButton.apptentiveClose, let navigationControllerView = self.navigationController?.view {
                closeButton.addTarget(self, action: #selector(cancelSurvey), for: .touchUpInside)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                navigationControllerView.addSubview(closeButton)
                NSLayoutConstraint.activate([
                    closeButton.topAnchor.constraint(equalTo: navigationControllerView.topAnchor, constant: 47),
                    closeButton.trailingAnchor.constraint(equalTo: navigationControllerView.trailingAnchor, constant: -12),
                    closeButton.heightAnchor.constraint(equalToConstant: 34),
                    closeButton.widthAnchor.constraint(equalToConstant: 34),
                ])
                if self.viewModel.surveyDidSendResponse && self.viewModel.displayMode == .paged {
                    closeButton.removeFromSuperview()
                }
            }
        }
    }

    private func configureNavigationBar() {
        if let headerLogo = UIImage.apptentiveHeaderLogo {
            let headerImageView = UIImageView(image: headerLogo.withRenderingMode(.alwaysOriginal))
            headerImageView.contentMode = .scaleAspectFit
            self.navigationItem.titleView = headerImageView

        } else {
            self.navigationItem.title = self.viewModel.name
        }
    }

    private func cancel(partial: Bool = false) {
        self.viewModel.cancel(partial: partial)
        self.dismiss()
    }

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func scrollToFirstInvalidQuestion() {
        if let firstInvalidQuestionIndex = self.viewModel.invalidQuestionIndexes.min() {
            let visibleRect = CGRect(origin: self.tableView.contentOffset, size: self.tableView.bounds.size).inset(by: self.tableView.contentInset)

            if visibleRect.contains(self.tableView.rectForHeader(inSection: firstInvalidQuestionIndex)) {
                UIAccessibility.post(notification: .layoutChanged, argument: self.tableView.headerView(forSection: firstInvalidQuestionIndex))
            } else {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: firstInvalidQuestionIndex), at: .middle, animated: true)
            }
        }
    }
}
