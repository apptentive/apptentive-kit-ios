//
//  SurveyViewModel+ChoiceQuestion.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/14/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation

extension SurveyViewModel {
    /// Represents a question where the user can select from a collection of predefined answers.
    public class ChoiceQuestion: Question {
        /// An array of Choice view models representing the answer choices.
        public let choices: [Choice]

        /// Toggles the answer choice at the specified index.
        ///
        /// In the case of a questions whose `selectionStyle` is `.radioButton`, toggling an already-selected choice has no effect.
        /// - Parameter index: the index of the choice to toggle.
        public func toggleChoice(at index: Int) {
            switch self.selectionStyle {
            case .checkbox:
                self.choices[index].isSelected.toggle()

            case .radioButton:
                self.choices.forEach { $0.isSelected = false }
                self.choices[index].isSelected = true
            }

            self.choices.forEach { (choice) in
                choice.checkIfFixed()
            }

            self.updateSelection()
        }

        /// The selection behavior of the answer choices.
        public var selectionStyle: SelectionStyle {
            switch self.type {
            case .radio, .range:
                return .radioButton
            case .checkbox:
                return .checkbox
            case .freeform:
                apptentiveCriticalError("toggleChoice called on freeform question type")
                return .checkbox
            }
        }

        /// Defines the selection behavior of answer choices, which can be indicated to the user through e.g. a button image.
        public enum SelectionStyle {
            /// A question where the user can select any number of answer choices.
            case checkbox

            /// A question where the user can select exactly one answer choice.
            ///
            /// Initially no choices are selected.
            /// Selecting another choice de-selects the currently selected choice.
            /// Attempting to de-select the currently-selected choice has no effect.
            case radioButton
        }

        private let type: SurveyConfiguration.Question.QuestionType
        private let minSelections: Int
        private let maxSelections: Int

        override init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.choices = (question.answerChoices ?? []).map({ (choice) in
                Choice(choice: choice)
            })
            self.type = question.type

            if question.type == .radio || question.type == .range {
                self.minSelections = question.required ?? false ? 1 : 0
                self.maxSelections = 1
            } else {
                self.minSelections = question.minSelections ?? 0
                self.maxSelections = question.maxSelections ?? Int.max
            }

            super.init(question: question, requiredText: requiredText)

            self.choices.forEach { (choice) in
                choice.questionViewModel = self
            }
        }

        override var isValid: Bool {
            let selectedChoiceCount = self.choices.filter({ $0.isSelected }).count

            let doesNotExceedMaxCount = selectedChoiceCount <= self.maxSelections
            let meetsMinCount = selectedChoiceCount >= self.minSelections
            let choicesAreValid = self.choices.allSatisfy { $0.isValid }
            let isOptional = !self.isRequired

            return doesNotExceedMaxCount && choicesAreValid && (meetsMinCount || isOptional)
        }

        override var response: QuestionResponse {
            let answers = self.choices.compactMap { $0.responsePart }

            return answers.isEmpty ? .empty : .answered(answers)
        }

        override func validate() {
            super.validate()

            for choice in self.choices {
                choice.validate()
            }
        }

        /// Describes a choice that can be selected for a choice question type.

        public class Choice: Validating {
            /// The label to be shown as part of the choice user interface.
            public let label: String

            /// The placeholder text for the "Other" text field.
            public let placeholderText: String?

            /// Indicates whether a freeform "Other" text field should be shown for the choice.
            public let supportsOther: Bool

            /// Indicates whether the user has selected this choice.
            ///
            /// This should not be modified by the view controller. Use the
            /// question's `toggleChoice(at:)` method instead.
            public internal(set) var isSelected: Bool

            /// Whether the user interface should indicate this choice as having an invalid response.
            ///
            /// This should not be modified by the view controller.
            public internal(set) var isMarkedAsInvalid: Bool {
                didSet {
                    if isMarkedAsInvalid != oldValue {
                        guard let question = self.questionViewModel, let surveyViewModel = question.surveyViewModel else {
                            return apptentiveCriticalError("Should have a view model set")
                        }

                        surveyViewModel.setNeedsUpdateValidation()
                    }
                }
            }

            /// The freeform "Other" text entered by the user for this choice.
            public var value: String? {
                didSet {
                    self.checkIfFixed()

                    guard let question = self.questionViewModel else {
                        return apptentiveCriticalError("Should have a choice question set.")
                    }

                    question.checkIfFixed()
                }
            }

            init(choice: SurveyConfiguration.Question.Choice) {
                self.label = choice.value
                self.id = choice.id
                self.placeholderText = choice.placeholderText
                self.isSelected = false
                self.isMarkedAsInvalid = false

                switch choice.type {
                case .other:
                    self.supportsOther = true

                default:
                    self.supportsOther = false
                }
            }

            weak var questionViewModel: SurveyViewModel.ChoiceQuestion?

            var isValid: Bool {
                if self.supportsOther && self.isSelected {
                    return self.trimmedOtherText != nil
                } else {
                    return true
                }
            }

            var responsePart: Answer? {
                if self.isSelected {
                    if self.supportsOther {
                        guard let otherText = self.value else {
                            return nil
                        }

                        return .other(self.id, otherText)
                    } else {
                        return .choice(self.id)
                    }
                } else {
                    return nil
                }
            }

            func validate() {
                self.isMarkedAsInvalid = !self.isValid
            }

            private let id: String

            private var trimmedOtherText: String? {
                if let trimmed = self.value?.trimmingCharacters(in: .whitespacesAndNewlines), trimmed.count > 0 {
                    return trimmed
                } else {
                    return nil
                }
            }
        }
    }
}
