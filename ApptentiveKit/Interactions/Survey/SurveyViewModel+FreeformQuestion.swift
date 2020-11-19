//
//  SurveyViewModel+FreeformQuestion.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/14/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation

public extension SurveyViewModel {
    /// Represents a question where the user can enter arbitrary text.
    class FreeformQuestion: Question {
        /// The text to display as a placeholder for e.g. a `UITextField` control.
        public let placeholderText: String?

        /// Whether the response should allow more than a single line of text.
        public let allowMultipleLines: Bool

        /// The text of the user's current answer to the question.
        public var answerText: String? {
            didSet {
                self.updateValidation()
            }
        }

        override init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.placeholderText = question.placeholderText
            self.allowMultipleLines = question.multiline ?? false

            super.init(question: question, requiredText: requiredText)
        }

        private var trimmedAnswerText: String? {
            if let result = self.answerText?.trimmingCharacters(in: .whitespacesAndNewlines), result.count > 0 {
                return result
            } else {
                return nil
            }
        }

        override var response: [SurveyQuestionResponse]? {
            if let trimmedAnswer = self.trimmedAnswerText {
                return [.freeform(trimmedAnswer)]
            } else {
                return nil
            }
        }
    }
}
