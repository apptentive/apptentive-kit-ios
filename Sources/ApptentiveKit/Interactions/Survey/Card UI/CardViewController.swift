//
//  CardViewController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/5/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class CardViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate, UITextViewDelegate, SurveyViewModelDelegate {
    let viewModel: SurveyViewModel

    let scrollView: UIScrollView
    let indicatorView: SurveyIndicator
    let nextButton: AdvanceButton

    var currentQuestionView: QuestionCardView
    var previousQuestionView: QuestionCardView

    var currentLeadingConstraint, previousLeadingConstraint: NSLayoutConstraint

    var currentQuestionIndex: Int = 0 {
        didSet {
            self.didChangeQuestionIndex()
        }
    }

    var numberOfPreviousQuestions: Int = 0

    var currentQuestion: SurveyViewModel.Question {
        self.viewModel.questions[self.currentQuestionIndex]
    }

    static let choiceTagOffset = 42
    static let otherTagOffset = 42 << 16

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel

        self.scrollView = UIScrollView(frame: .zero)
        self.indicatorView = SurveyIndicator(frame: .zero)
        self.nextButton = AdvanceButton(frame: .zero)
        self.currentQuestionView = QuestionCardView(frame: .zero)
        self.previousQuestionView = QuestionCardView(frame: .zero)

        self.currentLeadingConstraint = NSLayoutConstraint()
        self.previousLeadingConstraint = NSLayoutConstraint()

        super.init(nibName: nil, bundle: nil)

        self.scrollView.delegate = self
        self.viewModel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = UIView()
        self.view.backgroundColor = .white
    }

    override func viewDidLoad() {
        self.navigationItem.title = self.viewModel.name
        if #available(iOS 13.0, *) {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(dismissMe))
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissMe))
        }

        self.view.addSubview(self.scrollView)
        self.view.addSubview(self.indicatorView)
        self.view.addSubview(self.nextButton)

        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.indicatorView.translatesAutoresizingMaskIntoConstraints = false
        self.nextButton.translatesAutoresizingMaskIntoConstraints = false

        self.currentQuestionView.translatesAutoresizingMaskIntoConstraints = false
        self.previousQuestionView.translatesAutoresizingMaskIntoConstraints = false

        self.scrollView.addSubview(self.previousQuestionView)
        self.scrollView.addSubview(self.currentQuestionView)

        NSLayoutConstraint.activate([
            self.scrollView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.scrollView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            self.scrollView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            self.nextButton.topAnchor.constraint(equalToSystemSpacingBelow: self.scrollView.bottomAnchor, multiplier: 2),
            self.nextButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.indicatorView.topAnchor.constraint(equalToSystemSpacingBelow: self.nextButton.bottomAnchor, multiplier: 2),
            self.indicatorView.leadingAnchor.constraint(equalToSystemSpacingAfter: self.view.safeAreaLayoutGuide.leadingAnchor, multiplier: 2),
            self.view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: self.indicatorView.trailingAnchor, multiplier: 2),
            self.indicatorView.heightAnchor.constraint(equalToConstant: 5),
            self.view.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: self.indicatorView.bottomAnchor, multiplier: 2),
            self.currentQuestionView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.currentQuestionView.heightAnchor.constraint(equalTo: self.scrollView.heightAnchor),
            self.scrollView.widthAnchor.constraint(equalTo: self.currentQuestionView.widthAnchor, constant: 16),
            self.previousQuestionView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
            self.previousQuestionView.heightAnchor.constraint(equalTo: self.scrollView.heightAnchor),
            self.scrollView.widthAnchor.constraint(equalTo: self.previousQuestionView.widthAnchor, constant: 16),
        ])

        self.currentLeadingConstraint = self.currentQuestionView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8)
        self.previousLeadingConstraint = self.previousQuestionView.leadingAnchor.constraint(equalTo: self.scrollView.leadingAnchor, constant: 8)

        self.currentLeadingConstraint.isActive = true
        self.previousLeadingConstraint.isActive = true

        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.clipsToBounds = false

        self.nextButton.setTitle("Next", for: .normal)
        self.nextButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        self.nextButton.addTarget(self, action: #selector(advance), for: .touchUpInside)

        self.indicatorView.numberOfSegments = self.viewModel.questions.count
    }

    override func viewWillAppear(_ animated: Bool) {
        self.didChangeQuestionIndex()
    }

    override func viewDidLayoutSubviews() {
        self.adjustScrollView()
    }

    // Actions

    @objc func advance(_ sender: AnyObject) {
        let lastQuestionIndex = self.viewModel.questions.count - 1

        if self.currentQuestionIndex == lastQuestionIndex {
            self.viewModel.submit()
        } else {
            self.viewModel.validateQuestion(self.currentQuestion)

            if self.currentQuestion.isValid {
                // Work around a bug where changing contentSize changes the contentOffset (sometimes)
                let contentOffset = self.scrollView.contentOffset
                self.currentQuestionIndex += 1
                self.scrollView.contentOffset = contentOffset

                self.scrollView.setContentOffset(CGPoint(x: self.scrollView.bounds.width * CGFloat(self.numberOfPreviousQuestions), y: 0), animated: true)
            }
        }
    }

    @objc func dismissMe() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func toggle(_ sender: UIButton) {
        guard let choiceQuestion = self.currentQuestion as? SurveyViewModel.ChoiceQuestion else {
            return assertionFailure("Got a range event on a non-range question")
        }

        let index = sender.tag - Self.choiceTagOffset

        choiceQuestion.toggleChoice(at: index)
    }

    @objc func choose(_ sender: UISegmentedControl) {
        guard let rangeQuestion = self.currentQuestion as? SurveyViewModel.RangeQuestion else {
            return assertionFailure("Got a range event on a non-range question")
        }

        rangeQuestion.selectValue(at: sender.selectedSegmentIndex)
    }

    @objc func textFieldDidChange(_ sender: UITextField) {
        if let freeformQuestion = self.currentQuestion as? SurveyViewModel.FreeformQuestion {
            freeformQuestion.value = sender.text
        } else if let choiceQuestion = self.currentQuestion as? SurveyViewModel.ChoiceQuestion {
            choiceQuestion.choices[sender.tag - Self.otherTagOffset].value = sender.text
        } else {
            assertionFailure("Text field sending events to wrong question")
        }
    }

    // MARK: - Text Field Delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if self.currentQuestion is SurveyViewModel.FreeformQuestion || (self.currentQuestion as? SurveyViewModel.ChoiceQuestion)?.selectionStyle == .radioButton {
            self.advance(textField)
        }

        if self.currentQuestion.isValid {
            textField.resignFirstResponder()
        }

        return false
    }

    // MARK: - Text View Delegate

    func textViewDidChange(_ textView: UITextView) {
        guard let question = self.currentQuestion as? SurveyViewModel.FreeformQuestion else {
            return assertionFailure("Text view sending delegate calls to wrong question")
        }

        question.value = textView.text
    }

    // MARK: - Scroll View Delegate

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.currentQuestionIndex = Int(floor(self.scrollView.contentOffset.x / self.scrollView.bounds.width))
    }

    // MARK: - Survey View Model Delegate

    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel) {
        self.dismissMe()
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        self.currentQuestionView.errorLabel.alpha = self.currentQuestion.isMarkedAsInvalid ? 1 : 0
        self.currentQuestionView.instructionsLabel.textColor = self.currentQuestion.isMarkedAsInvalid ? .apptentiveError : .apptentiveInstructionsLabel

        switch self.currentQuestion {
        case let freeformQuestion as SurveyViewModel.FreeformQuestion:
            if freeformQuestion.allowMultipleLines {
                guard let textView = self.currentQuestionView.stackView.arrangedSubviews[2] as? UITextView else {
                    return assertionFailure("Expected third arranged subview to be text view")
                }

                textView.layer.borderColor = (self.currentQuestion.isMarkedAsInvalid ? UIColor.apptentiveError : UIColor.apptentiveTextInputBorder).cgColor
            } else {
                guard let textField = self.currentQuestionView.stackView.arrangedSubviews[2] as? UITextField else {
                    return assertionFailure("Expected third arranged subview to be text view")
                }

                textField.layer.borderColor = (self.currentQuestion.isMarkedAsInvalid ? UIColor.apptentiveError : UIColor.clear).cgColor
            }
            break

        case let choiceQuestion as SurveyViewModel.ChoiceQuestion:
            var indexOffset = 2

            choiceQuestion.choices.enumerated().forEach { (index, choice) in
                if choice.supportsOther && choice.isSelected {
                    indexOffset += 1

                    choice.updateMarkedAsInvalid()

                    guard let textField = self.currentQuestionView.stackView.arrangedSubviews[index + indexOffset] as? UITextField else {
                        return assertionFailure("Expected third arranged subview to be text view")
                    }

                    textField.layer.borderColor = (choice.isMarkedAsInvalid ? UIColor.apptentiveError : UIColor.clear).cgColor
                }
            }

            break

        default:
            break
        }
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        guard let choiceQuestion = viewModel.questions[self.currentQuestionIndex] as? SurveyViewModel.ChoiceQuestion else {
            return  // no choice question currently visible
        }

        var startingStackViewIndex = 2
        choiceQuestion.choices.enumerated().forEach { (index, choice) in
            guard let button = self.currentQuestionView.viewWithTag(index + Self.choiceTagOffset) as? UIButton else {
                return assertionFailure("Current question view's subview with tag \(index) should be a button.")
            }

            button.isSelected = choice.isSelected

            if choice.supportsOther {
                let textField = self.currentQuestionView.viewWithTag(index + Self.otherTagOffset)

                if choice.isSelected {
                    startingStackViewIndex += 1
                    if textField == nil {
                        let textField = Self.buildTextField(for: choice, at: index, delegate: self)
                        self.currentQuestionView.stackView.insertArrangedSubview(textField, at: index + startingStackViewIndex)
                        textField.becomeFirstResponder()
                    }
                } else if let textField = textField, !choice.isSelected {
                    self.currentQuestionView.stackView.removeArrangedSubview(textField)
                    textField.removeFromSuperview()
                }
            }
        }
    }

    // MARK: - Private

    private func didChangeQuestionIndex() {
        self.indicatorView.selectedSegmentIndex = currentQuestionIndex
        self.numberOfPreviousQuestions = currentQuestionIndex  // TODO: Subtract any skipped questions

        if currentQuestionIndex == self.viewModel.questions.count - 1 {
            self.nextButton.setTitle("Submit", for: .normal)
        } else {
            self.nextButton.setTitle("Next", for: .normal)
        }

        let nextQuestionView = self.previousQuestionView
        let nextQuestionLeadingConstraint = self.previousLeadingConstraint

        self.previousQuestionView = self.currentQuestionView
        self.previousLeadingConstraint = self.currentLeadingConstraint

        self.currentQuestionView = nextQuestionView
        self.currentLeadingConstraint = nextQuestionLeadingConstraint

        let previousQuestion = self.currentQuestionIndex > 0 ? self.viewModel.questions[self.currentQuestionIndex - 1] : nil
        self.setQuestion(question: previousQuestion, for: previousQuestionView, questionIndex: self.currentQuestionIndex - 1)

        self.setQuestion(question: self.currentQuestion, for: currentQuestionView, questionIndex: self.currentQuestionIndex)

        self.adjustScrollView()
    }

    private func adjustScrollView() {
        self.scrollView.contentSize = CGSize(width: self.scrollView.bounds.width * CGFloat(self.numberOfPreviousQuestions + 1), height: self.scrollView.bounds.height)

        self.currentLeadingConstraint.constant = 8 + self.scrollView.contentSize.width - self.scrollView.bounds.width
        self.previousLeadingConstraint.constant = 8 + self.scrollView.contentSize.width - self.scrollView.bounds.width * 2

        self.scrollView.layoutIfNeeded()
    }

    private func setQuestion(question: SurveyViewModel.Question?, for cardView: QuestionCardView, questionIndex: Int) {
        cardView.introductionLabel.text = self.viewModel.introduction
        cardView.questionLabel.text = question?.text
        cardView.instructionsLabel.text = [question?.requiredText, question?.instructions].compactMap { $0 }.joined(separator: "—")
        cardView.stackView.arrangedSubviews.suffix(from: 2).forEach { arrangedSubview in
            cardView.stackView.removeArrangedSubview(arrangedSubview)
            arrangedSubview.removeFromSuperview()
        }

        cardView.introductionLabel.alpha = (questionIndex == 0) ? 1 : 0

        switch question {
        case let choiceQuestion as SurveyViewModel.ChoiceQuestion:
            choiceQuestion.choices.enumerated().forEach { (index, choice) in
                let choiceButton = Self.buildChoiceButton(for: choice, at: index, selectionStyle: choiceQuestion.selectionStyle, delegate: self)
                cardView.stackView.addArrangedSubview(choiceButton)

                if choice.isSelected && choice.supportsOther {
                    let textField = Self.buildTextField(for: choice, at: index, delegate: self)
                    cardView.stackView.addArrangedSubview(textField)
                }
            }
            break

        case let freeformQuestion as SurveyViewModel.FreeformQuestion:
            if freeformQuestion.allowMultipleLines {
                let textView = Self.buildTextView(for: freeformQuestion, delegate: self)
                cardView.stackView.addArrangedSubview(textView)

                if !freeformQuestion.hasAnswer {
                    textView.becomeFirstResponder()
                }
            } else {
                let textField = Self.buildTextField(for: freeformQuestion, delegate: self)
                cardView.stackView.addArrangedSubview(textField)

                if !freeformQuestion.hasAnswer {
                    textField.becomeFirstResponder()
                }
            }
            break

        case let rangeQuestion as SurveyViewModel.RangeQuestion:
            let (rangeControl, minMaxView) = Self.buildRangeControl(for: rangeQuestion, delegate: self)
            cardView.stackView.addArrangedSubview(rangeControl)
            cardView.stackView.addArrangedSubview(minMaxView)
            break

        default:
            // Unknown question type
            break
        }

        cardView.errorLabel.text = question?.errorMessage
        cardView.stackView.addArrangedSubview(cardView.errorLabel)
        cardView.errorLabel.alpha = question?.isMarkedAsInvalid == true ? 1 : 0

        cardView.setNeedsLayout()
    }

    private static func buildChoiceButton(for choice: SurveyViewModel.ChoiceQuestion.Choice, at index: Int, selectionStyle: SurveyViewModel.ChoiceQuestion.SelectionStyle, delegate: CardViewController) -> UIButton {
        let choiceButton = ChoiceButton(frame: .zero)

        choiceButton.setTitle(choice.label, for: .normal)
        choiceButton.isSelected = choice.isSelected
        choiceButton.tag = index + self.choiceTagOffset

        switch selectionStyle {
        case .radioButton:
            choiceButton.setImage(.apptentiveRadioButton, for: .normal)
            choiceButton.setImage(.apptentiveRadioButtonSelected, for: .selected)
            choiceButton.setImage(.apptentiveRadioButtonSelected, for: .highlighted)
        case .checkbox:
            choiceButton.setImage(.apptentiveCheckbox, for: .normal)
            choiceButton.setImage(.apptentiveCheckboxSelected, for: .selected)
            choiceButton.setImage(.apptentiveCheckboxSelected, for: .highlighted)
        }

        choiceButton.adjustsImageSizeForAccessibilityContentSizeCategory = true
        choiceButton.adjustsImageWhenHighlighted = true

        choiceButton.titleLabel?.font = .apptentiveChoiceLabel
        choiceButton.titleLabel?.numberOfLines = 0
        choiceButton.titleLabel?.adjustsFontForContentSizeCategory = true
        choiceButton.setTitleColor(.apptentiveChoiceLabel, for: .normal)

        choiceButton.contentHorizontalAlignment = .leading
        choiceButton.contentVerticalAlignment = .center
        choiceButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        choiceButton.addTarget(delegate, action: #selector(toggle(_:)), for: .touchUpInside)

        return choiceButton
    }

    private static func buildTextField(for question: TextFieldPopulating, at index: Int = 0, delegate: CardViewController) -> UITextField {
        let textField = UITextField(frame: .zero)

        textField.text = question.value
        textField.placeholder = question.placeholderText
        textField.tag = index + Self.otherTagOffset

        textField.adjustsFontForContentSizeCategory = true
        textField.font = .apptentiveChoiceLabel
        textField.textColor = .apptentiveChoiceLabel
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .next

        // Create our own border to show validation state, match color with text view border
        textField.layer.borderWidth = 1.0 / textField.traitCollection.displayScale
        textField.layer.borderColor = UIColor.clear.cgColor
        textField.layer.cornerRadius = 6.0

        textField.delegate = delegate
        textField.addTarget(delegate, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

        return textField
    }

    private static func buildTextView(for question: SurveyViewModel.FreeformQuestion, delegate: CardViewController) -> UITextView {
        let textView = UITextView(frame: .zero)

        textView.text = question.value
        // TODO: create fake placeholder

        textView.adjustsFontForContentSizeCategory = true
        textView.font = .apptentiveChoiceLabel
        textView.textColor = .apptentiveChoiceLabel

        textView.layer.borderColor = UIColor.apptentiveTextInputBorder.cgColor
        textView.layer.borderWidth = 1.0 / textView.traitCollection.displayScale
        textView.layer.cornerRadius = 6.0

        NSLayoutConstraint.activate([
            textView.heightAnchor.constraint(equalToConstant: 200)
        ])

        textView.delegate = delegate

        return textView
    }

    private static func buildRangeControl(for rangeQuestion: SurveyViewModel.RangeQuestion, delegate: CardViewController) -> (UISegmentedControl, UIStackView) {
        let rangeControl = UISegmentedControl(frame: .zero)
        rangeQuestion.choiceLabels.enumerated().forEach { (index, choiceLabel) in
            rangeControl.insertSegment(withTitle: choiceLabel, at: index, animated: false)
        }

        if let selectedSegmentIndex = rangeQuestion.selectedValueIndex {
            rangeControl.selectedSegmentIndex = selectedSegmentIndex
        }
        rangeControl.addTarget(delegate, action: #selector(choose(_:)), for: .valueChanged)

        let minLabel = UILabel(frame: .zero)
        minLabel.text = rangeQuestion.minText
        minLabel.adjustsFontForContentSizeCategory = true
        minLabel.numberOfLines = 0
        minLabel.font = .apptentiveMinMaxLabel

        let maxLabel = UILabel(frame: .zero)
        maxLabel.text = rangeQuestion.maxText
        maxLabel.adjustsFontForContentSizeCategory = true
        maxLabel.numberOfLines = 0
        maxLabel.font = .apptentiveMinMaxLabel
        maxLabel.textAlignment = .right

        let minMaxView = UIStackView(arrangedSubviews: [minLabel, maxLabel])
        minMaxView.axis = .horizontal

        return (rangeControl, minMaxView)
    }
}

protocol TextFieldPopulating {
    var value: String? { get }
    var placeholderText: String? { get }
}

extension SurveyViewModel.FreeformQuestion: TextFieldPopulating {}

extension SurveyViewModel.ChoiceQuestion.Choice: TextFieldPopulating {}
