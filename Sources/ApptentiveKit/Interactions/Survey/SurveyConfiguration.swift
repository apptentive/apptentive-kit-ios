//
//  SurveyConfiguration.swift
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
struct SurveyConfiguration: Decodable {
    let name: String?
    let title: String?
    let submitText: String?
    let validationError: String?
    let introduction: String?
    let thankYouMessage: String?
    let shouldShowThankYou: Bool
    let requiredText: String?
    let required: Bool?
    let closeConfirmationTitle: String?
    let closeConfirmationMessage: String?
    let closeConfirmationCloseButtonText: String?
    let closeConfirmationBackButtonText: String?
    let questions: [Question]
    let presentationStyle: PresentationStyle?
    let termsAndConditions: TermsAndConditions?

    enum PresentationStyle: String, Decodable {
        case list
        case card
    }

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
        case presentationStyle = "presentation_style"
        case termsAndConditions = "terms_and_conditions"
        case questions
    }

    struct TermsAndConditions: Decodable {
        let label: String
        let link: URL
    }

    struct Question: Decodable, Identifiable {
        let id: String
        let text: String
        let type: QuestionType
        let errorMessage: String
        let required: Bool

        let instructions: String?
        let answerChoices: [Choice]?
        let minSelections: Int?
        let maxSelections: Int?

        let multiline: Bool?
        let placeholderText: String?

        let rangeMin: Int?
        let rangeMax: Int?
        let rangeMinText: String?
        let rangeMaxText: String?

        enum CodingKeys: String, CodingKey {
            case id
            case text = "value"
            case type
            case instructions
            case errorMessage = "error_message"
            case required

            case answerChoices = "answer_choices"
            case minSelections = "min_selections"
            case maxSelections = "max_selections"
            case multiline
            case placeholderText = "freeform_hint"

            case rangeMin = "min"
            case rangeMax = "max"
            case rangeMinText = "min_label"
            case rangeMaxText = "max_label"
        }

        enum QuestionType: String, Decodable {
            case radio = "multichoice"
            case checkbox = "multiselect"
            case freeform = "singleline"
            case range
        }

        struct Choice: Decodable, Identifiable {
            let id: String
            let value: String
            let type: ChoiceType?

            let placeholderText: String?

            enum CodingKeys: String, CodingKey {
                case id
                case value
                case type
                case placeholderText = "hint"
            }

            enum ChoiceType: String, Decodable {
                case option = "select_option"
                case other = "select_other"
            }
        }
    }
}
