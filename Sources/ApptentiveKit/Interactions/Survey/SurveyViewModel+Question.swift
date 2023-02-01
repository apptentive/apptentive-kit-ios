//
//  SurveyViewModel+Question.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/14/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation

extension SurveyViewModel {
    /// Base class for question view models (should be treated as abstract).
    public class Question: Validating {
        weak var surveyViewModel: SurveyViewModel?
        let questionID: String

        /// The text of the question.
        public let text: String

        /// Whether a response to the question is required.
        public let isRequired: Bool

        /// The text to display to indicate that a question is required.
        public let requiredText: String?

        /// The text to display when the response to the question is invalid.
        public let errorMessage: String

        /// The text to display with the question to indicate validation requirements.
        public let instructions: String?

        /// The response object that will make up part of the survey response API request.
        var response: QuestionResponse {
            apptentiveCriticalError("Abstract method called")
            return .empty
        }

        /// The actual valididty of the answer(s).
        var isValid: Bool {
            return !(self.isRequired && self.response == .empty)
        }

        /// Whether a response has been entered.
        var hasAnswer: Bool {
            return self.response != .empty
        }

        /// Whether the UI should show the question as invalid.
        public var isMarkedAsInvalid = false {
            didSet {
                if isMarkedAsInvalid != oldValue {
                    guard let surveyViewModel = self.surveyViewModel else {
                        return apptentiveCriticalError("Should have a view model set")
                    }

                    surveyViewModel.setNeedsUpdateValidation()
                }
            }
        }

        /// Returns the accessibility label for question/instructions/error.
        public var accessibilityLabel: String {
            var result = [String]()

            if self.isMarkedAsInvalid {
                result.append(self.errorMessage)
            }

            result.append(self.text)

            if self.isRequired, let requiredText = self.requiredText {
                result.append(". \(requiredText)")
            }

            if let instructions = self.instructions {
                result.append(". \(instructions)")
            }

            return result.joined(separator: " ")
        }

        init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.questionID = question.id
            self.text = question.text
            self.isRequired = question.required ?? false
            self.requiredText = question.required ?? false ? (requiredText ?? NSLocalizedString("SurveyRequiredText", tableName: "Localizable", bundle: .module, value: "Required", comment: "Text indicating survey is required")) : nil
            self.errorMessage = question.errorMessage
            self.instructions = question.instructions
        }

        func updateSelection() {
            self.checkIfFixed()

            guard let surveyViewModel = self.surveyViewModel else {
                return apptentiveCriticalError("Should have a view model set")
            }

            surveyViewModel.delegate?.surveyViewModelSelectionDidChange(surveyViewModel)
        }

        func validate() {
            self.isMarkedAsInvalid = !self.isValid
        }
    }
}

protocol Validating: AnyObject {
    var isMarkedAsInvalid: Bool { get set }
    var isValid: Bool { get }

    func validate()
    func checkIfFixed()
}

extension Validating {
    func checkIfFixed() {
        if self.isValid {
            self.isMarkedAsInvalid = false
        }
    }
}
