//
//  SurveyViewModel+RangeQuestion.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/14/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation

public extension SurveyViewModel {
    /// Represents a question where the user can select a single value from a contiguous range of integers.
    class RangeQuestion: ChoiceQuestion {
        /// The minimum value that a user can select.
        public let minValue: Int

        /// The maximum value that a user can select.
        public let maxValue: Int

        /// The text to display alongside the choice having the minimum value.
        public let minText: String?

        /// The text to display alongside the choice having the maximium value.
        public let maxText: String?

        override init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.minValue = question.rangeMin ?? 0
            self.maxValue = question.rangeMax ?? 10
            self.minText = question.rangeMinText
            self.maxText = question.rangeMaxText

            super.init(question: question, requiredText: requiredText)
        }

        /// The text labels to display for each answer choice.
        public override var choiceLabels: [String] {
            Array(minValue...maxValue).map({ String($0) })
        }

        override func responsePart(for index: Int) -> SurveyQuestionResponse {
            return .range(index + self.minValue)
        }
    }
}
