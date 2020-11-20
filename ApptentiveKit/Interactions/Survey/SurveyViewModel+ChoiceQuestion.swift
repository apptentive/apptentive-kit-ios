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
        private let choices: [SurveyConfiguration.Question.Choice]
        private let type: SurveyConfiguration.Question.QuestionType
        private let minSelections: Int
        private let maxSelections: Int

        /// An `IndexSet` containing the indexes of the choice(s) selected by the user.
        ///
        /// To alter this value, see `toggleChoice(at:)`.
        public private(set) var selectedChoiceIndexes: IndexSet {
            didSet {
                if selectedChoiceIndexes != oldValue {
                    self.updateSelection()
                }
            }
        }

        override init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.choices = question.answerChoices ?? []
            self.type = question.type

            if question.type == .radio || question.type == .range {
                self.minSelections = question.required ? 1 : 0
                self.maxSelections = 1
            } else {
                self.minSelections = question.minSelections ?? 0
                self.maxSelections = question.maxSelections ?? Int.max
            }

            self.selectedChoiceIndexes = IndexSet()

            super.init(question: question, requiredText: requiredText)
        }

        override var isValid: Bool {
            let doesNotExceedMaxCount = self.selectedChoiceIndexes.count <= self.maxSelections
            let meetsMinCount = self.selectedChoiceIndexes.count >= self.minSelections
            let isOptional = !self.isRequired

            return doesNotExceedMaxCount && (meetsMinCount || isOptional)
        }

        /// Toggles the answer choice at the specified index.
        ///
        /// In the case of a questions whose `selectionStyle` is `.radioButton`, toggling an already-selected choice has no effect.
        /// - Parameter index: the index of the choice to toggle.
        public func toggleChoice(at index: Int) {
            switch self.selectionStyle {
            case .checkbox:
                self.selectedChoiceIndexes.toggle(index)

            case .radioButton:
                self.selectedChoiceIndexes.choose(index)
            }

            self.updateValidation()
        }

        /// The text labels to display for each answer choice.
        public var choiceLabels: [String] {
            return choices.map({ $0.value })
        }

        /// The selection behavior of the answer choices.
        public var selectionStyle: SelectionStyle {
            switch self.type {
            case .radio, .range:
                return .radioButton
            case .checkbox:
                return .checkbox
            case .freeform:
                assertionFailure("toggleChoice called on freeform question type")
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
            /// Attempting to de-select the currently-selected choice has no effect.f
            case radioButton
        }

        func responsePart(for index: Int) -> SurveyQuestionResponse {
            return .choice(self.choices[index].id)
        }

        override var response: [SurveyQuestionResponse]? {
            return selectedChoiceIndexes.isEmpty ? nil : self.selectedChoiceIndexes.map({ self.responsePart(for: $0) })
        }

        private func updateSelection() {
            guard let surveyViewModel = self.surveyViewModel else {
                return assertionFailure("Should have a view model set")
            }

            surveyViewModel.delegate?.surveyViewModelSelectionDidChange(surveyViewModel)
        }
    }
}

extension IndexSet {
    fileprivate mutating func choose(_ index: Int) {
        self.removeAll()
        self.update(with: index)
    }

    fileprivate mutating func toggle(_ index: Int) {
        if self.contains(index) {
            self.remove(index)
        } else {
            self.update(with: index)
        }
    }
}
