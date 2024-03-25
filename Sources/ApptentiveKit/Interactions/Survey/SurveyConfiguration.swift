//
//  SurveyV12Configuration.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 7/8/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object corresponding to the `configuration` object in an interaction of type `Survey` when the API version is 12.
///
/// This object is intended to faithfully represent the data retrieved as part of the engagement manfiest.
/// The SurveyBranchedViewModel receives this object in its initializer  to display in its UI.
struct SurveyConfiguration: Decodable {
    let title: String
    let name: String?
    let introduction: String?
    let successMessage: String?
    let shouldShowSuccessMessage: Bool
    let validationError: String
    let requiredText: String
    let closeConfirmationTitle: String
    let closeConfirmationMessage: String
    let closeConfirmationCloseButtonTitle: String
    let closeConfirmationBackButtonTitle: String
    let questionSets: [QuestionSet]
    let termsAndConditions: TermsAndConditions?
    let renderAs: RenderAs
    let introButtonTitle: String?
    let successButtonTitle: String?
    let disclaimerText: String?

    enum CodingKeys: String, CodingKey {
        case title
        case name
        case introduction = "description"
        case successMessage = "success_message"
        case shouldShowSuccessMessage = "show_success_message"
        case validationError = "validation_error"
        case requiredText = "required_text"
        case closeConfirmationTitle = "close_confirm_title"
        case closeConfirmationMessage = "close_confirm_message"
        case closeConfirmationCloseButtonTitle = "close_confirm_close_text"
        case closeConfirmationBackButtonTitle = "close_confirm_back_text"
        case termsAndConditions = "terms_and_conditions"
        case questionSets = "question_sets"
        case renderAs = "render_as"
        case introButtonTitle = "intro_button_text"
        case successButtonTitle = "success_button_text"
        case disclaimerText = "disclaimer_text"
    }

    struct TermsAndConditions: Decodable {
        let label: String
        let link: URL
    }

    struct Question: Decodable {
        let id: String
        let text: String
        let type: QuestionType
        let errorMessage: String
        let required: Bool?

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

        struct Choice: Decodable {
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

    struct QuestionSet: Decodable {
        let id: String
        let order: Int?
        let invokes: [Invocation]
        let questions: [SurveyConfiguration.Question]
        let buttonTitle: String

        enum CodingKeys: String, CodingKey {
            case id
            case order
            case invokes
            case questions
            case buttonTitle = "button_text"
        }

        struct Invocation: Decodable {
            let behavior: Behavior
            let criteria: Criteria?

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                let nextQuestionSetID = try container.decodeIfPresent(String.self, forKey: .nextQuestionSetID)
                let behavior = try container.decode(RawBehavior.self, forKey: .behavior)

                switch (behavior, nextQuestionSetID) {
                case (.end, .none):
                    self.behavior = .end

                case (.continue, .some(let nextQuestionSetID)):
                    self.behavior = .continue(nextQuestionSetID: nextQuestionSetID)

                default:
                    throw ApptentiveError.internalInconsistency
                }

                self.criteria = try container.decodeIfPresent(Criteria.self, forKey: .criteria)
            }

            enum CodingKeys: String, CodingKey {
                case behavior
                case nextQuestionSetID = "next_question_set_id"
                case criteria
            }

            enum RawBehavior: String, Decodable {
                case `continue`
                case end
            }

            enum Behavior {
                case `continue`(nextQuestionSetID: String)
                case end
            }
        }
    }

    enum RenderAs: String, Decodable {
        case paged
        case list
    }
}
