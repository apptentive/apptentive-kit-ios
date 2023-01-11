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

    /// Tells the delegate that it should dismiss the survey UI.
    /// - Parameter viewModel: The view model sending the message.
    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel)

    /// Tells the delegate that the valid status of one or more questions has changed.
    /// - Parameter viewModel: The view model sending the message.
    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel)

    /// Tells the delegate that the selection status of one or more question choices has changed.
    /// - Parameter viewModel: The view model sending the message.
    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel)

    /// Tells the delegate that the contents of a page of the survey will change.
    /// - Parameter viewModel: The view model sending the message.
    func surveyViewModelPageWillChange(_ viewModel: SurveyViewModel)

    /// Tells the delegate that the contents of a page of the survey did change.
    /// - Parameter viewModel: The view model sending the message.
    func surveyViewModelPageDidChange(_ viewModel: SurveyViewModel)
}

typealias SurveyInteractionDelegate = EventEngaging & ResponseSending & ResponseRecording & URLOpening & SurveyBranching

/// A class that describes the data in a survey interaction and allows reponses to be gathered and transmitted.
public class SurveyViewModel {

    /// The name of the survey, typically displayed in a navigation bar.
    public let name: String?

    /// Whether the user should be prevented from dismissing the survey.
    public let isRequired: Bool

    /// For branched surveys, the number of segments to show in the page indicator.
    public let pageIndicatorSegmentCount: Int

    /// A message shown to the user after trying to advance or submit when one or more questions have invalid answers.
    public let validationErrorMessage: String

    /// An optional legal disclaimer to show users.
    public let disclaimerText: String?

    /// An object describing the terms and conditions to be shown in the survey.
    public struct TermsAndConditions {

        /// Non-linked text to be shown before the link text.
        let preamble: String?

        /// The text that should open the link to the terms and conditions document when tapped.
        let linkLabel: String

        /// The URL to open when the text is tapped.
        internal let linkURL: URL
    }

    /// The terms and conditions data for the survey.
    public let termsAndConditions: TermsAndConditions?

    /// An object describing the close confirmation alert for the survey.
    public struct CloseConfirmation {

        /// The title for the alert.
        let title: String

        /// The message for the alert.
        let message: String

        /// The label for the botton that returns to the survey.
        let continueButtonTitle: String

        /// The label for the button that closes the survey.
        let closeButtonTitle: String
    }

    /// The close confirmation data for the survey.
    public let closeConfirmation: CloseConfirmation

    /// An object that updates UI in response to a change in the view model.
    public weak var delegate: SurveyViewModelDelegate?

    /// The view model for the current page of the survey to display.
    public var currentPage: Page {
        guard let result = self.pages[self.currentPageID] else {
            apptentiveCriticalError("Current page ID not found in pages.")
            return Page.invalid
        }

        return result
    }

    /// The question view models for the current page.
    public var questions: [SurveyViewModel.Question] {
        return self.currentPage.questions
    }

    /// Whether there are any invalid questions that the user has not yet updated their response for.
    public var isMarkedAsInvalid: Bool {
        return self.questions.contains(where: \.isMarkedAsInvalid)
    }

    /// A short message shown to the user after the survey is submitted successfully (in list rendering mode).
    public var thankYouMessage: String? {
        return self.successMessage
    }

    /// A short description of the survey typically displayed between the name and the question list (in list rendering mode).
    public var introduction: String? {
        return self.currentPage.description
    }

    /// The label text for the button that submits the survey (in list rendering mode) or advances to the next page (in paged rendering mode).
    public var advanceButtonText: String {
        return self.currentPage.advanceButtonLabel
    }

    /// Returns the indexes of any questions (on the current page) that do not satisfy their validation requirements.
    public var invalidQuestionIndexes: IndexSet {
        return IndexSet(self.questions.enumerated().filter { !$0.element.isValid }.map { $0.offset })
    }

    /// Whether any questions (in the entire survey) have been responded to.
    public var hasAnswer: Bool {
        return self.allQuestions.contains(where: { $0.hasAnswer })
    }

    /// Method that should be called in response to the user tapping the terms and conditions link.
    public func openTermsAndConditions() {
        guard let termsLink = self.termsAndConditions?.linkURL else {
            return apptentiveCriticalError("Attempting to open terms and conditions, but URL is missing.")
        }

        self.interactionDelegate.open(termsLink) { _ in }
    }

    /// Update the `isMarkedAsInvalid` flag based on the whether the number of choices matches the requirements.
    /// - Parameter question: the question whose answers should be validate.
    public func validateQuestion(_ question: SurveyViewModel.Question) {
        if let choiceQuestion = question as? SurveyViewModel.ChoiceQuestion {
            choiceQuestion.choices.forEach { choice in
                choice.isMarkedAsInvalid = !choice.isValid
            }
        }

        question.isMarkedAsInvalid = !question.isValid
    }

    /// Submits the users answers to the survey.
    ///
    /// If one or more answers are invalid, the delegate's `surveyViewModelValidationDidChange(_:)` will be called.
    /// If the answers are valid and there are more pages, the delegate's `surveyViewModelPageDidChange(_:)` will be called (via the `advanceToNextPage` method).
    /// If the answers are valid and there are no more pages, the delegate's `surveyViewModelDidSubmit(_:)` will be called.
    public func advance() {
        if self.isValid {
            if self.surveyIsOnLastQuestionPage {
                self.response.questionResponses.forEach { questionID, responses in
                    self.interactionDelegate.recordResponse(responses, for: questionID)
                }

                self.interactionDelegate.engage(event: .submit(from: self.interaction))
                self.interactionDelegate.send(surveyResponse: self.response)

                self.surveyDidSendAnswers = true
            }

            if self.surveyIsOnLastPage {
                self.delegate?.surveyViewModelDidSubmit(self)
            } else {
                for question in self.currentPage.questions {
                    self.interactionDelegate.setCurrentResponse(question.response, for: question.questionID)
                }

                self.advanceToNextPage()
            }
        } else {
            self.questions.forEach { question in
                self.validateQuestion(question)
            }
            self.delegate?.surveyViewModelValidationDidChange(self)
        }
    }

    /// Whether any questions have been responded to.
    public var isValid: Bool {
        return self.questions.allSatisfy(\.isValid)
    }

    /// Describes how the survey should be displayed.
    public enum DisplayMode {

        /// Display in list mode.
        case list

        /// Display in paged mode.
        case paged
    }

    /// How the survey should be displayed.
    public var displayMode: DisplayMode {
        return self.pages.count == 1 ? .list : .paged
    }

    /// Whether the survey answers have been sent to the API.
    public var surveyDidSendAnswers: Bool = false

    /// Whether an attempt to close the survey should warn about discarding answers.
    public var shouldConfirmCancel: Bool {
        switch self.displayMode {
        case .list:
            return self.hasAnswer

        case .paged:
            return self.hasAnswer && !self.surveyDidSendAnswers
        }
    }

    /// The value to indicate in the page indicator.
    public var currentSelectedSegmentIndex: Int? {
        return self.currentPage.pageIndicatorValue
    }

    /// Registers that the survey was launched.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))

        for question in self.allQuestions {
            self.interactionDelegate.resetCurrentResponse(for: question.questionID)
        }
    }

    /// Registers that the survey was continued when the user was presented with the close confimation view.
    public func continuePartial() {
        self.interactionDelegate.engage(event: .continuePartial(from: self.interaction))
    }

    /// Registers that the survey was cancelled by the user.
    /// - Parameter partial: Boolean value to indicate whether the survey was closed after selection was made.
    public func cancel(partial: Bool) {
        switch partial {
        case true:
            self.interactionDelegate.engage(event: .cancelPartial(from: self.interaction))
        case false:
            self.interactionDelegate.engage(event: .cancel(from: self.interaction))
        }

        for question in self.allQuestions {
            self.interactionDelegate.resetCurrentResponse(for: question.questionID)
        }
    }

    // MARK: - Internal

    internal let interaction: Interaction
    internal let interactionDelegate: SurveyInteractionDelegate
    internal let rangeChoiceLabelNumberFormatter: NumberFormatter
    internal var currentPageID: String
    internal var pages: [String: Page]
    internal var visitedQuestionIDs: Set<String>
    internal let successMessage: String?
    internal let finalQuestionPageID: String
    internal let title: String?

    internal required init(configuration: SurveyConfiguration, interaction: Interaction, interactionDelegate: SurveyInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate

        self.title = configuration.title
        self.name = configuration.name

        self.termsAndConditions = configuration.termsAndConditions.flatMap {
            TermsAndConditions(preamble: nil, linkLabel: $0.label, linkURL: $0.link)
        }

        self.closeConfirmation = CloseConfirmation(
            title: configuration.closeConfirmationTitle,
            message: configuration.closeConfirmationMessage,
            continueButtonTitle: configuration.closeConfirmationBackButtonTitle,
            closeButtonTitle: configuration.closeConfirmationCloseButtonTitle)

        var pages = [String: Page]()

        switch configuration.renderAs {
        case .list:
            self.pageIndicatorSegmentCount = 0

            self.successMessage = configuration.shouldShowSuccessMessage ? configuration.successMessage : nil

            let questions = Self.buildQuestionViewModels(questions: configuration.questionSets.flatMap { $0.questions }, requiredText: configuration.requiredText)
            let submitButtonText = configuration.questionSets.last?.buttonTitle ?? "Submit"

            let singlePage = Page(id: "single", description: configuration.introduction, questions: questions, advanceButtonLabel: submitButtonText, advanceLogic: [])
            pages[singlePage.id] = singlePage
            self.currentPageID = singlePage.id
            self.finalQuestionPageID = singlePage.id

        case .paged:
            self.pageIndicatorSegmentCount = configuration.questionSets.count

            // Success message (if any) will be shown on its own page.
            self.successMessage = nil

            guard let firstQuestionSetID = configuration.questionSets.first?.id, let lastQuestionSetID = configuration.questionSets.last?.id else {
                apptentiveCriticalError("Expected at least one question set in the survey.")
                let invalidPage = Page.invalid
                pages[invalidPage.id] = invalidPage
                self.currentPageID = invalidPage.id
                self.finalQuestionPageID = invalidPage.id
                break
            }

            if let introduction = configuration.introduction, let introButtonTitle = configuration.introButtonTitle {
                let introPage = Page(id: "intro", description: introduction, advanceButtonLabel: introButtonTitle, advanceLogic: [AdvanceLogic(criteria: .true, pageID: firstQuestionSetID)])
                pages[introPage.id] = introPage
                self.currentPageID = introPage.id
            } else {
                self.currentPageID = firstQuestionSetID
            }

            var successPageID: String?

            if configuration.shouldShowSuccessMessage, let successMessage = configuration.successMessage, let successButtonTitle = configuration.successButtonTitle {
                let successPage = Page(id: "success", description: successMessage, questions: [], advanceButtonLabel: successButtonTitle, advanceLogic: [])
                pages[successPage.id] = successPage
                successPageID = successPage.id
            }

            for (index, questionSet) in configuration.questionSets.enumerated() {
                let questions = Self.buildQuestionViewModels(questions: questionSet.questions, requiredText: configuration.requiredText)

                let advanceLogic = questionSet.invokes.compactMap { (invocation) -> AdvanceLogic? in
                    switch invocation.behavior {
                    case .end:
                        if let successPageID = successPageID {
                            return AdvanceLogic(criteria: .true, pageID: successPageID)
                        } else {
                            return nil
                        }

                    case .continue(let nextQuestionSetID):
                        return AdvanceLogic(criteria: invocation.criteria ?? .true, pageID: nextQuestionSetID)
                    }
                }

                let questionPage = Page(id: questionSet.id, questions: questions, advanceButtonLabel: questionSet.buttonTitle, pageIndicatorValue: index, advanceLogic: advanceLogic)

                pages[questionPage.id] = questionPage
            }

            self.finalQuestionPageID = lastQuestionSetID
        }

        self.pages = pages

        self.rangeChoiceLabelNumberFormatter = NumberFormatter()
        self.isRequired = false
        self.validationErrorMessage = configuration.validationError
        self.disclaimerText = configuration.disclaimerText

        self.visitedQuestionIDs = Set<String>()
        self.currentPage.questions.forEach { self.visitedQuestionIDs.insert($0.questionID) }

        for questionViewModel in self.allQuestions {
            questionViewModel.surveyViewModel = self
        }
    }

    internal init(configuration: SurveyV11Configuration, interaction: Interaction, interactionDelegate: SurveyInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate

        self.title = configuration.title
        self.name = configuration.name

        self.termsAndConditions = configuration.termsAndConditions.flatMap {
            TermsAndConditions(preamble: nil, linkLabel: $0.label, linkURL: $0.link)
        }

        self.closeConfirmation = CloseConfirmation(
            title: configuration.closeConfirmationTitle,
            message: configuration.closeConfirmationMessage,
            continueButtonTitle: configuration.closeConfirmationBackButtonText,
            closeButtonTitle: configuration.closeConfirmationCloseButtonText)

        self.pageIndicatorSegmentCount = 0
        let questions = Self.buildQuestionViewModels(questions: configuration.questions, requiredText: configuration.requiredText)

        let singlePage = Page(id: "single", description: configuration.introduction, questions: questions, advanceButtonLabel: configuration.submitText, advanceLogic: [])
        self.pages = [singlePage.id: singlePage]
        self.currentPageID = singlePage.id
        self.finalQuestionPageID = singlePage.id

        self.validationErrorMessage = configuration.validationError
        self.successMessage = configuration.shouldShowThankYou ? configuration.thankYouMessage : nil
        self.isRequired = configuration.required ?? false
        self.disclaimerText = nil

        self.rangeChoiceLabelNumberFormatter = NumberFormatter()

        self.visitedQuestionIDs = Set<String>()
        self.currentPage.questions.forEach { self.visitedQuestionIDs.insert($0.questionID) }

        for questionViewModel in self.allQuestions {
            questionViewModel.surveyViewModel = self
        }
    }

    internal var response: SurveyResponse {
        let questionResponseTuples: [(String, QuestionResponse)] = self.allQuestions.map({ question in
            // response defaults to .empty and must be changed to .skipped if the question wasn't visited.
            let response = self.visitedQuestionIDs.contains(question.questionID) ? question.response : .skipped

            return (question.questionID, response)
        })

        let questionResponses = Dictionary(uniqueKeysWithValues: questionResponseTuples)

        return SurveyResponse(surveyID: self.interaction.id, questionResponses: questionResponses)
    }

    internal var allQuestions: [SurveyViewModel.Question] {
        return self.pages.values.flatMap { $0.questions }
    }

    internal var surveyIsOnLastQuestionPage: Bool {
        return self.currentPageID == self.finalQuestionPageID
    }

    internal var surveyIsOnLastPage: Bool {
        return self.currentPage.advanceLogic.count == 0
    }

    /// Sets the current question set and the question list with the new ones based on the selected answer.
    internal func advanceToNextPage() {
        self.interactionDelegate.getNextPageID(for: currentPage.advanceLogic) { (result: Result<String?, Error>) in
            if let nextPageID: String = {
                switch result {
                case .success(.some(let nextPageID)):
                    return nextPageID

                case .success(.none):
                    return nil

                case .failure(let error):
                    apptentiveCriticalError("Error evaluating logic for paged survey: \(error)")
                    return nil
                }
            }() {

                DispatchQueue.main.async {
                    self.delegate?.surveyViewModelPageWillChange(self)
                    self.currentPageID = nextPageID
                    self.delegate?.surveyViewModelPageDidChange(self)

                    self.currentPage.questions.forEach { self.visitedQuestionIDs.insert($0.questionID) }
                }
            } else {
                DispatchQueue.main.async {
                    self.delegate?.surveyViewModelDidSubmit(self)
                }
            }
        }
    }

    internal static func buildQuestionViewModels(questions: [SurveyConfiguration.Question], requiredText: String?) -> [SurveyViewModel.Question] {
        // Bail if we have non-unique question IDs.
        let questionIDs = questions.map { $0.id }
        guard questionIDs.sorted() == Array(Set(questionIDs)).sorted() else {
            apptentiveCriticalError("Question IDs are not unique!")
            return []
        }

        return questions.map { question in
            switch question.type {
            case .radio, .checkbox:
                return SurveyViewModel.ChoiceQuestion(question: question, requiredText: requiredText)
            case .range:
                return SurveyViewModel.RangeQuestion(question: question, requiredText: requiredText)
            case .freeform:
                return SurveyViewModel.FreeformQuestion(question: question, requiredText: requiredText)
            }
        }
    }
}

struct AdvanceLogic {
    let criteria: Criteria
    let pageID: String
}

extension Criteria {
    static let `true` = Criteria(subClauses: [])
}
