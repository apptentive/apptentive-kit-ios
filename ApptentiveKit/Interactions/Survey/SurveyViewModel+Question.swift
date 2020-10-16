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
    public class Question {
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
        var response: [SurveyQuestionResponse]? {
            assertionFailure("Abstract method called")
            return nil
        }

        /// The actual valididty of the answer(s).
        var isValid: Bool {
            return !(self.isRequired && self.response == nil)
        }

        /// Whether the UI should show the question as invalid.
        public var isMarkedAsInvalid = false

        init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.questionID = question.id
            self.text = question.text
            self.isRequired = question.required
            self.requiredText = question.required ? (requiredText ?? "Required") : nil
            self.errorMessage = question.errorMessage
            self.instructions = question.instructions
        }

        func updateValidation() {
            if self.isMarkedAsInvalid && self.isValid {
                self.isMarkedAsInvalid = false

                guard let surveyViewModel = self.surveyViewModel else {
                    return assertionFailure("Should have a view model set")
                }

                surveyViewModel.delegate?.surveyViewModelValidationDidChange(surveyViewModel)
            }
        }
    }
}
