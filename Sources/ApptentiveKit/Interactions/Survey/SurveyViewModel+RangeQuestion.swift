//
//  SurveyViewModel+RangeQuestion.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/14/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation

extension SurveyViewModel {
    /// Represents a question where the user can select a single value from a contiguous range of integers.
    public class RangeQuestion: Question {
        /// The minimum value that a user can select.
        public let minValue: Int

        /// The maximum value that a user can select.
        public let maxValue: Int

        /// The text to display alongside the choice having the minimum value.
        public let minText: String?

        /// The text to display alongside the choice having the maximium value.
        public let maxText: String?

        /// The value that was selected by the user, if any.
        public private(set) var selectedValueIndex: Int?

        /// The text labels to display for each answer choice.
        public var choiceLabels: [String] {
            // TODO: Use a number formatter? (for e.g. Arabic)
            Array(minValue...maxValue).map({ String($0) })
        }

        /// Used to indicate that the user has selected the choice at the given index.
        /// - Parameter index: The index of the choice that was selected.
        public func selectValue(at index: Int) {
            self.selectedValueIndex = index
            self.updateSelection()
        }

        override init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.minValue = question.rangeMin ?? 0
            self.maxValue = question.rangeMax ?? 10
            self.minText = question.rangeMinText
            self.maxText = question.rangeMaxText

            super.init(question: question, requiredText: requiredText)
        }

        override var response: [Answer]? {
            self.selectedValueIndex.flatMap {
                [Answer.range($0 + self.minValue)]
            }
        }
        public func accessibilityHintForSegment() -> String {
            let minValue = String(self.minValue)
            let maxValue = String(self.maxValue)

            return "Where \(minValue) is \(minText ?? "the least") and \(maxValue) is \(maxText ?? "the most")"
        }
    }
}
