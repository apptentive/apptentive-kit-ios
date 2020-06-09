//
//  SurveyViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation

class SurveyViewModel {
    let surveyID: String
    let title: String
    let submitButtonText: String
    let validationErrorMessage: String
    let introduction: String
    let thankYouMessage: String?
    let shouldShowThankYou: Bool
    let required: Bool
    let questions: [Question]

    required init(interaction: Interaction) {
        self.surveyID = interaction.id

        self.title = interaction.configuration.title
        self.submitButtonText = interaction.configuration.submitText
        self.validationErrorMessage = interaction.configuration.validationError
        self.introduction = interaction.configuration.introduction
        self.thankYouMessage = interaction.configuration.thankYouMessage
        self.shouldShowThankYou = interaction.configuration.shouldShowThankYou
        self.required = interaction.configuration.required
        self.questions = interaction.configuration.questions.map { Question(question: $0, requiredText: interaction.configuration.requiredText) }

        self.questions.forEach { (questionViewModel) in
            questionViewModel.surveyViewModel = self
        }
    }

    class Question {
        weak var surveyViewModel: SurveyViewModel?
        let questionID: String
        let text: String
        let required: Bool
        let requiredText: String?
        let errorMessage: String
        let instructions: String?

        init(question: SurveyConfiguration.Question, requiredText: String?) {
            self.questionID = question.id
            self.text = question.text
            self.required = question.required
            self.requiredText = question.required ? (requiredText ?? "Required") : nil
            self.errorMessage = question.errorMessage
            self.instructions = question.instructions
        }

        var instructionsText: String {
            [self.requiredText, self.instructions].compactMap({ $0 }).joined(separator: "—")
        }
    }
}
