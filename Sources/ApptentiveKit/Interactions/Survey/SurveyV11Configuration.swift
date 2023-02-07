//
//  SurveyV11Configuration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object corresponding to the `configuration` object in an interaction of type `Survey`.
///
/// This object is intended to faithfully represent the data retrieved as part
/// of the engagement manfiest. In cases where a question has type-specific
/// parameters, all possible parameters are available for all question types.
/// The view model should massage these values into per-question-type
/// objects for the UI to display.
struct SurveyV11Configuration: Decodable {
    let name: String?
    let title: String?
    let submitText: String
    let validationError: String
    let introduction: String?
    let thankYouMessage: String?
    let shouldShowThankYou: Bool
    let requiredText: String
    let required: Bool?
    let closeConfirmationTitle: String
    let closeConfirmationMessage: String
    let closeConfirmationCloseButtonText: String
    let closeConfirmationBackButtonText: String
    let questions: [SurveyConfiguration.Question]
    let termsAndConditions: TermsAndConditions?

    enum CodingKeys: String, CodingKey {
        case name
        case title
        case submitText = "submit_text"
        case validationError = "validation_error"
        case introduction = "description"
        case thankYouMessage = "success_message"
        case shouldShowThankYou = "show_success_message"
        case requiredText = "required_text"
        case required
        case closeConfirmationTitle = "close_confirm_title"
        case closeConfirmationMessage = "close_confirm_message"
        case closeConfirmationCloseButtonText = "close_confirm_close_text"
        case closeConfirmationBackButtonText = "close_confirm_back_text"
        case termsAndConditions = "terms_and_conditions"
        case questions
    }

    struct TermsAndConditions: Decodable {
        let label: String
        let link: URL
    }
}
