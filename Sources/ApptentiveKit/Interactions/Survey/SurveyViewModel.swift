//
//  SurveyViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the interface that users of the view model should conform to to receive updates in response to user actions.
public protocol SurveyViewModelDelegate: class {
    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel)
    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel)
    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel)
}

/// A class that describes the data in a survey interaction and allows reponses to be gathered and transmitted.
public class SurveyViewModel {
    let interactionDelegate: EventEngaging & ResponseSending

    let interaction: Interaction

    /// The name of the survey, typically displayed in a navigation bar.
    public let name: String?

    /// The label text for the button that submits the survey.
    public let submitButtonText: String

    /// A message shown to the user after submitting when one or more questions have invalid answers.
    public let validationErrorMessage: String

    /// A short description of the survey typically displayed between the name and the question list.
    public let introduction: String?

    /// A short message shown to the user after the survey is submitted successfully.
    public let thankYouMessage: String?

    /// Whether the user should be allowed to dismiss the survey.
    public let isRequired: Bool

    /// The list of questions in the survey.
    public let questions: [Question]

    /// The title text for the alert asking the user if they want to close a partially-completed survey.
    public let closeConfirmationAlertTitle: String

    /// The message text for the alert asking the user if they want to close a partially-completed survey.
    public let closeConfirmationAlertMessage: String

    /// The text for the button returning the user to a partially-completed survey.
    public let closeConfirmationBackButtonLabel: String

    /// The text for the button confirming the closure of a partially-completed survey.
    public let closeConfirmationCloseButtonLabel: String

    /// An object, typically a view controller, that implements the `SurveyViewModelDelegate` protocol to receive updates when the survey data changes.
    public weak var delegate: SurveyViewModelDelegate?

    required init(configuration: SurveyConfiguration, interaction: Interaction, interactionDelegate: EventEngaging & ResponseSending) {
        self.interaction = interaction

        self.name = configuration.name
     
        self.submitButtonText = configuration.submitText ?? NSLocalizedString("SurveySubmitButtonText", tableName: "Localizable", bundle: Bundle.module, value: "Submit", comment: "Survey submit button title")
        self.validationErrorMessage =
            configuration.validationError ?? NSLocalizedString("SurveyErrorMessage", tableName: "Localizable", bundle: Bundle.module, value: "There are issues with your responses.", comment: "Survey error validation message")
        self.introduction = configuration.introduction
        self.thankYouMessage = configuration.shouldShowThankYou ? configuration.thankYouMessage : nil
        self.isRequired = configuration.required ?? false
        self.questions = Self.buildQuestionViewModels(questions: configuration.questions, requiredText: configuration.requiredText)
        self.interactionDelegate = interactionDelegate

        self.closeConfirmationAlertTitle = NSLocalizedString("CloseSurveyAlertTitle", tableName: "Localizable", bundle: Bundle.module, value: "Close survey?", comment: "Survey close confirmation alert title")

        self.closeConfirmationAlertMessage = NSLocalizedString(
            "CloseConfirmationAlertMessage", tableName: "Localizable", bundle: Bundle.module, value: "You will lose your progress if you close this survey.", comment: "Survey close confirmation alert message")

        self.closeConfirmationBackButtonLabel = NSLocalizedString("CloseConfirmationBackButton", tableName: "Localizable", bundle: Bundle.module, value: "Back to Survey", comment: "Survey close confirmation back button")

        self.closeConfirmationCloseButtonLabel = NSLocalizedString("CloseConfirmationCloseButton", tableName: "Localizable", bundle: Bundle.module, value: "Close", comment: "Survey close confirmation close button")

        self.questions.forEach { (questionViewModel) in
            questionViewModel.surveyViewModel = self
        }
    }

    private static func buildQuestionViewModels(questions: [SurveyConfiguration.Question], requiredText: String?) -> [Question] {
        // Bail if we have non-unique question IDs.
        let questionIDs = questions.map { $0.id }
        guard questionIDs.sorted() == Array(Set(questionIDs)).sorted() else {
            assertionFailure("Question IDs are not unique!")
            return []
        }

        return questions.map { question in
            switch question.type {
            case .radio, .checkbox:
                return ChoiceQuestion(question: question, requiredText: requiredText)
            case .range:
                return RangeQuestion(question: question, requiredText: requiredText)
            case .freeform:
                return FreeformQuestion(question: question, requiredText: requiredText)
            }
        }
    }

    var response: SurveyResponse {
        // Construct a dictionary where the keys are question IDs and the values are responses.
        let questionResponses = Dictionary(uniqueKeysWithValues: self.questions.map({ ($0.questionID, $0.response) })).compactMapValues({ $0 })

        return SurveyResponse(surveyID: self.interaction.id, answers: questionResponses)
    }

    /// A value that indicates the responses to all questions satisfy their validation requirements.
    public var isValid: Bool {
        return self.questions.allSatisfy(\.isValid)
    }

    /// Whether any questions have been responded to.
    public var hasAnswer: Bool {
        return self.questions.contains(where: \.hasAnswer)
    }
    /// Whether there are any invalid questions that the user has not yet updated their response for.
    public var isMarkedAsInvalid: Bool {
        return self.questions.contains(where: \.isMarkedAsInvalid)
    }

    /// Returns the indexes of any questions that do not satisfy their validation requirements.
    public var invalidQuestionIndexes: IndexSet {
        return IndexSet(self.questions.enumerated().filter { !$0.element.isValid }.map { $0.offset })
    }

    /// Submits the users answers to the survey.
    ///
    /// If the answers are valid, the delegate's `surveyViewModelDidSubmit(_:)` will be called.
    /// If one or more answers are invalid, the delegate's `surveyViewModelValidationDidChange(_:)` will be called.
    public func submit() {
        if self.isValid {
            self.interactionDelegate.send(surveyResponse: self.response)

            self.interactionDelegate.engage(event: .submit(from: self.interaction))

            self.delegate?.surveyViewModelDidSubmit(self)
        } else {
            self.questions.forEach { question in
                question.isMarkedAsInvalid = !question.isValid

                if let choiceQuestion = question as? ChoiceQuestion {
                    choiceQuestion.choices.forEach { choice in
                        choice.isMarkedAsInvalid = !choice.isValid
                    }
                }
            }

            self.delegate?.surveyViewModelValidationDidChange(self)
        }
    }

    /// Registers that the survey was successfully presented to the user.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))
    }

    /// Registers that the survey was cancelled by the user.
    public func cancel() {
        self.interactionDelegate.engage(event: .cancel(from: self.interaction))
    }
}
