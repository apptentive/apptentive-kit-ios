//
//  SurveyViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the interface that users of the view model should conform to to receive updates in response to user actions.
public protocol SurveyViewModelDelegate: AnyObject {
    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel)
    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel)
    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel)
}

typealias SurveyInteractionDelegate = EventEngaging & ResponseSending & ResponseRecording & URLOpening

/// A class that describes the data in a survey interaction and allows reponses to be gathered and transmitted.
public class SurveyViewModel {
    let interaction: Interaction
    let interactionDelegate: SurveyInteractionDelegate

    /// Whether to display the survey as a vertically-scrolling list or a series of horizontally-scrolling cards.
    let presentationStyle: SurveyConfiguration.PresentationStyle

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

    /// The label for an optional link to the terms and conditions for the survey.
    public var termsAndConditionsLabel: String?

    /// The number formatter used to produce choice label strings for range questions.
    public var rangeChoiceLabelNumberFormatter: NumberFormatter

    required init(configuration: SurveyConfiguration, interaction: Interaction, interactionDelegate: SurveyInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate

        self.presentationStyle = configuration.presentationStyle ?? .list
        self.name = configuration.name
        self.submitButtonText = configuration.submitText ?? "Submit"
        self.validationErrorMessage =
            configuration.validationError ?? "There are issues with your responses."
        self.introduction = configuration.introduction
        self.thankYouMessage = configuration.shouldShowThankYou ? configuration.thankYouMessage : nil
        self.isRequired = configuration.required ?? false
        self.questions = Self.buildQuestionViewModels(questions: configuration.questions, requiredText: configuration.requiredText)
        self.termsAndConditionsLabel = configuration.termsAndConditions?.label
        self.termsAndConditionsURL = configuration.termsAndConditions?.link
        self.closeConfirmationAlertTitle =
            configuration.closeConfirmationTitle ?? "Close survey?"
        self.closeConfirmationAlertMessage =
            configuration.closeConfirmationMessage ?? "You will lose your progress if you close this survey."
        self.closeConfirmationBackButtonLabel =
            configuration.closeConfirmationBackButtonText ?? "Back to Survey"
        self.closeConfirmationCloseButtonLabel =
            configuration.closeConfirmationCloseButtonText ?? "Close"
        self.rangeChoiceLabelNumberFormatter = NumberFormatter()
        self.questions.forEach { (questionViewModel) in
            questionViewModel.surveyViewModel = self
        }
    }

    private static func buildQuestionViewModels(questions: [SurveyConfiguration.Question], requiredText: String?) -> [Question] {
        // Bail if we have non-unique question IDs.
        let questionIDs = questions.map { $0.id }
        guard questionIDs.sorted() == Array(Set(questionIDs)).sorted() else {
            apptentiveCriticalError("Question IDs are not unique!")
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

            self.response.answers.forEach { questionID, responses in
                self.interactionDelegate.recordResponse(responses, for: questionID)
            }

            self.delegate?.surveyViewModelDidSubmit(self)
        } else {
            self.questions.forEach { question in
                self.validateQuestion(question)
            }

            self.delegate?.surveyViewModelValidationDidChange(self)
        }
    }

    /// Update the `isMarkedAsInvalid` flag based on the whether the number of choices matches the requirements.
    /// - Parameter question: the question whose answers should be validate.
    public func validateQuestion(_ question: Question) {
        if let choiceQuestion = question as? ChoiceQuestion {
            choiceQuestion.choices.forEach { choice in
                choice.isMarkedAsInvalid = !choice.isValid
            }
        }

        question.isMarkedAsInvalid = !question.isValid
    }

    /// Registers that the survey was successfully presented to the user.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))
    }

    /// Registers that the survey was cancelled by the user.
    /// - Parameter partial: Boolean value to indicate whether the survey was closed after selection was made.
    public func cancel(partial: Bool = false) {
        switch partial {
        case true:
            self.interactionDelegate.engage(event: .cancelPartial(from: interaction))
        case false:
            self.interactionDelegate.engage(event: .cancel(from: self.interaction))
        }
    }

    /// Registers that the survey was continued when the user was presented with the close confimation view.
    public func continuePartial() {
        self.interactionDelegate.engage(event: .continuePartial(from: interaction))
    }

    internal var termsAndConditionsURL: URL?

    /// Opens the link to the terms and conditions.
    public func openTermsAndConditions() {
        guard let termsLink = self.termsAndConditionsURL else {
            return apptentiveCriticalError("Attempting to open terms and conditions, but URL is missing.")
        }

        self.interactionDelegate.open(termsLink) { _ in }
    }
}
