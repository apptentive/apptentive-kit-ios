//
//  SurveyViewModel+Page.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/3/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

extension SurveyViewModel {

    /// Contains the information needed to display a page in a survey.
    public class Page {

        /// The identifier for the page.
        ///
        /// For pages corresponding to a question set, this will be the question set ID.
        /// For the introductory page, it will be "intro".
        /// For the success page, it will be "success".
        public let id: String

        /// Static text to display for the page.
        ///
        /// For list display mode, the text will be displayed at the top of the question list.
        /// For paged display mode, the text will be displayed in a centered label.
        public let description: String?

        /// The question view models corresponding to the questions to display on this page.
        public let questions: [SurveyViewModel.Question]

        /// The text to display in the advance/submit button.
        public let advanceButtonLabel: String

        /// The value to display in the page indicator for this page.
        ///
        /// A nil value indicates that the page indicator should be hidden.
        public let pageIndicatorValue: Int?

        // MARK: - Internal

        internal let advanceLogic: [AdvanceLogic]

        internal init(id: String, description: String? = nil, questions: [SurveyViewModel.Question] = [], advanceButtonLabel: String, pageIndicatorValue: Int? = nil, advanceLogic: [AdvanceLogic]) {
            self.id = id
            self.description = description
            self.questions = questions
            self.advanceButtonLabel = advanceButtonLabel
            self.pageIndicatorValue = pageIndicatorValue
            self.advanceLogic = advanceLogic
        }

        internal static let invalid = Page(id: "invalid", description: "An error has occurred.", advanceButtonLabel: "Close", advanceLogic: [])
    }
}
