//
//  SurveyResponse.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/12/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object describing a response to a survey.
struct SurveyResponse: Equatable {

    /// The interaction identifier associated with the survey.
    let surveyID: String

    /// A dictionary detailing the responses to each querstion.
    ///
    /// The keys are the identifiers for the question, and the values are an array of question response objects.
    /// Freeform, single-choice, and range responses will have one element in the array.
    let questionResponses: [String: QuestionResponse]
}
