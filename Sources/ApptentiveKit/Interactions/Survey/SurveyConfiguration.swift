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
    let introduction: AttributedString?
    let successMessage: AttributedString?
    let shouldShowSuccessMessage: Bool
    let validationError: AttributedString
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
    let disclaimerText: AttributedString?

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.introduction = try container.apptentiveDecodeHTMLIfPresent(forKey: .introduction)
        self.successMessage = try container.apptentiveDecodeHTMLIfPresent(forKey: .successMessage)
        self.shouldShowSuccessMessage = try container.decode(Bool.self, forKey: .shouldShowSuccessMessage)
        self.validationError = try container.apptentiveDecodeHTML(forKey: .validationError)
        self.requiredText = try container.decode(String.self, forKey: .requiredText)
        self.closeConfirmationTitle = try container.decode(String.self, forKey: .closeConfirmationTitle)
        self.closeConfirmationMessage = try container.decode(String.self, forKey: .closeConfirmationMessage)
        self.closeConfirmationCloseButtonTitle = try container.decode(String.self, forKey: .closeConfirmationCloseButtonTitle)
        self.closeConfirmationBackButtonTitle = try container.decode(String.self, forKey: .closeConfirmationBackButtonTitle)
        self.termsAndConditions = try container.decodeIfPresent(SurveyConfiguration.TermsAndConditions.self, forKey: .termsAndConditions)
        self.questionSets = try container.decode([SurveyConfiguration.QuestionSet].self, forKey: .questionSets)
        self.renderAs = try container.decode(SurveyConfiguration.RenderAs.self, forKey: .renderAs)
        self.introButtonTitle = try container.decodeIfPresent(String.self, forKey: .introButtonTitle)
        self.successButtonTitle = try container.decodeIfPresent(String.self, forKey: .successButtonTitle)
        self.disclaimerText = try container.apptentiveDecodeHTMLIfPresent(forKey: .disclaimerText)
    }

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
        let text: AttributedString
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

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            self.id = try container.decode(String.self, forKey: .id)
            self.text = try container.apptentiveDecodeHTML(forKey: .text)
            self.type = try container.decode(QuestionType.self, forKey: .type)
            self.errorMessage = try container.decode(String.self, forKey: .errorMessage)
            self.required = try container.decodeIfPresent(Bool.self, forKey: .required)

            self.instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
            self.answerChoices = try container.decodeIfPresent([Choice].self, forKey: .answerChoices)
            self.minSelections = try container.decodeIfPresent(Int.self, forKey: .minSelections)
            self.maxSelections = try container.decodeIfPresent(Int.self, forKey: .maxSelections)

            self.multiline = try container.decodeIfPresent(Bool.self, forKey: .multiline)
            self.placeholderText = try container.decodeIfPresent(String.self, forKey: .placeholderText)

            self.rangeMin = try container.decodeIfPresent(Int.self, forKey: .rangeMin)
            self.rangeMax = try container.decodeIfPresent(Int.self, forKey: .rangeMax)
            self.rangeMinText = try container.decodeIfPresent(String.self, forKey: .rangeMinText)
            self.rangeMaxText = try container.decodeIfPresent(String.self, forKey: .rangeMaxText)
        }

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
            let value: AttributedString
            let type: ChoiceType?

            let placeholderText: String?

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                self.id = try container.decode(String.self, forKey: .id)
                self.value = try container.apptentiveDecodeHTML(forKey: .value)
                self.type = try container.decodeIfPresent(ChoiceType.self, forKey: .type)

                self.placeholderText = try container.decodeIfPresent(String.self, forKey: .placeholderText)
            }

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
