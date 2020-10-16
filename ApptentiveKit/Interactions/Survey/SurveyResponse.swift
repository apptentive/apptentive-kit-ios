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
    let answers: [String: [SurveyQuestionResponse]]
}

/// An object describing a particular response.
///
/// Questions that accept multiple answers will have more than one question response in the array for a particular question.
enum SurveyQuestionResponse: Equatable {
    case choice(String)
    case freeform(String)
    case range(Int)
    case other(String, String)
}
