//
//  SurveyViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the interface that users of the view model should conform to to receive updates in response to user actions.
@MainActor public protocol SurveyViewModelDelegate: AnyObject {

    /// Tells the delegate that it should dismiss the survey UI.
    /// - Parameter viewModel: The view model sending the message.
    func surveyViewModelDidFinish(_ viewModel: SurveyViewModel)

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
@MainActor public class SurveyViewModel {

    /// The name of the survey, typically displayed in a navigation bar.
    public let name: String?

    /// Whether the user should be prevented from dismissing the survey.
    public let isRequired: Bool

    /// For branched surveys, the number of segments to show in the page indicator.
    public let pageIndicatorSegmentCount: Int

    /// A message shown to the user after trying to advance or submit when one or more questions have invalid answers.
    public let validationErrorMessage: AttributedString

    /// An optional legal disclaimer to show users.
    public var disclaimerText: AttributedString? {
        return self.currentPage.disclaimer
    }

    /// An object describing the terms and conditions to be shown in the survey.
    public struct TermsAndConditions {

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
    public var thankYouMessage: AttributedString? {
        return self.successMessage
    }

    /// A short description of the survey typically displayed between the name and the question list (in list rendering mode).
    public var introduction: AttributedString? {
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

    /// Whether the survey answers have been sent to the API.
    public var surveyDidSendResponse: Bool = false

    /// Indicates whether to highlight the first indicator segment when there is no intro screen.
    public var highlightFirstQuestionSegment: Bool = false

    /// Sets the text response value for the question/choice at the specified index path.
    /// - Parameters:
    ///   - value: The text value to set.
    ///   - indexPath: An index path with the index of the question and (if applicable) choice.
    public func setValue(_ value: String?, for indexPath: IndexPath) {
        switch self.questions[indexPath.section] {
        case let choiceQuestion as ChoiceQuestion:
            choiceQuestion.choices[indexPath.row].value = value

        case let freeformQuestion as FreeformQuestion:
            guard indexPath.row == 0 else {
                apptentiveCriticalError("Attempting to set text for a freeform question with nonzero row index")
                break
            }

            freeformQuestion.value = value

        default:
            apptentiveCriticalError("Attempting to set text for question/choice with no freeform value")
        }
    }

    /// Selects the value for the question at the index path's first index corresponding to the index path's second index.
    /// - Parameter indexPath: The index path specifying the question and value.
    public func selectValueFromRange(at indexPath: IndexPath) {
        guard let rangeQuestion = self.questions[indexPath.section] as? RangeQuestion else {
            return apptentiveCriticalError("Attempting to select value for non-range question")
        }

        rangeQuestion.selectValue(at: indexPath.row)
    }

    /// Method that should be called in response to the user tapping the terms and conditions link.
    public func openTermsAndConditions() {
        guard let termsLink = self.termsAndConditions?.linkURL else {
            return apptentiveCriticalError("Attempting to open terms and conditions, but URL is missing.")
        }

        Task {
            await self.interactionDelegate.open(termsLink)
        }
    }

    /// Submits the users answers to the survey.
    ///
    /// If one or more answers are invalid, the delegate's `surveyViewModelValidationDidChange(_:)` will be called.
    /// If the answers are valid and there are more pages, the delegate's `surveyViewModelPageDidChange(_:)` will be called (via the `advanceToNextPage` method).
    /// If the answers are valid and there are no more pages, the delegate's `surveyViewModelDidSubmit(_:)` will be called.
    public func advance() async {
        if self.isValid {
            for question in self.currentPage.questions {
                await self.interactionDelegate.setCurrentResponse(question.response, for: question.questionID)
            }

            do {
                try await self.advanceToNextPage()
            } catch let error {
                apptentiveCriticalError("Error evaluating logic for paged survey: \(error)")
            }

        } else {
            self.coalesceValidationChanges {
                for question in self.questions {
                    question.validate()
                }
            }

            if self.validationChanged {
                self.delegate?.surveyViewModelValidationDidChange(self)
            }
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

    /// Whether an attempt to close the survey should warn about discarding answers.
    public var shouldConfirmCancel: Bool {
        switch self.displayMode {
        case .list:
            return self.hasAnswer

        case .paged:
            return self.hasAnswer && !self.surveyDidSendResponse
        }
    }

    /// The value to indicate in the page indicator.
    public var currentSelectedSegmentIndex: Int? {
        return self.currentPage.pageIndicatorValue
    }

    /// Whether the current page is the introduction page.
    public var isIntroPage: Bool {
        return self.currentPageID == self.introPageID
    }

    /// Whether the current page is the success/thank-you page.
    public var isSuccessPage: Bool {
        return self.currentPageID == self.successPageID
    }

    /// Registers that the survey was launched.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))

        Task {
            for question in self.allQuestions {
                await self.interactionDelegate.resetCurrentResponse(for: question.questionID)
            }
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

        Task {
            for question in self.allQuestions {
                await self.interactionDelegate.resetCurrentResponse(for: question.questionID)
            }
        }
    }

    // MARK: - Internal

    internal let interaction: Interaction
    internal let interactionDelegate: SurveyInteractionDelegate
    internal let rangeChoiceLabelNumberFormatter: NumberFormatter
    internal var currentPageID: String
    internal let pages: [String: Page]
    internal var visitedQuestionIDs: Set<String>
    internal let successMessage: AttributedString?
    internal let title: String?
    internal let singlePageID = "single"
    internal let introPageID = "intro"
    internal let successPageID = "success"

    internal required init(configuration: SurveyConfiguration, interaction: Interaction, interactionDelegate: SurveyInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate

        self.title = configuration.title
        self.name = configuration.name

        self.termsAndConditions = configuration.termsAndConditions.flatMap {
            TermsAndConditions(linkLabel: $0.label, linkURL: $0.link)
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

            let singlePage = Page(id: self.singlePageID, description: configuration.introduction, disclaimer: configuration.disclaimerText, questions: questions, advanceButtonLabel: submitButtonText, advanceLogic: [])
            pages[singlePage.id] = singlePage
            self.currentPageID = singlePage.id

        case .paged:
            self.pageIndicatorSegmentCount = configuration.questionSets.count

            // Success message (if any) will be shown on its own page.
            self.successMessage = nil

            guard let firstQuestionSetID = configuration.questionSets.first?.id else {
                apptentiveCriticalError("Expected at least one question set in the survey.")
                let invalidPage = Page.invalid
                pages[invalidPage.id] = invalidPage
                self.currentPageID = invalidPage.id
                break
            }

            if configuration.introduction != nil || configuration.disclaimerText != nil {
                let introPage = Page(
                    id: self.introPageID, description: configuration.introduction, disclaimer: configuration.disclaimerText, advanceButtonLabel: configuration.introButtonTitle ?? "Begin",
                    advanceLogic: [AdvanceLogic(criteria: .true, pageID: firstQuestionSetID)])
                pages[introPage.id] = introPage
                self.currentPageID = introPage.id
            } else {
                self.highlightFirstQuestionSegment = true
                self.currentPageID = firstQuestionSetID
            }

            var successPageID: String?

            if configuration.shouldShowSuccessMessage, let successMessage = configuration.successMessage, let successButtonTitle = configuration.successButtonTitle {
                let successPage = Page(id: self.successPageID, description: successMessage, disclaimer: configuration.disclaimerText, questions: [], advanceButtonLabel: successButtonTitle, advanceLogic: [])
                pages[successPage.id] = successPage
                successPageID = successPage.id
            }

            for (index, questionSet) in configuration.questionSets.enumerated() {
                let questions = Self.buildQuestionViewModels(questions: questionSet.questions, requiredText: configuration.requiredText)

                let advanceLogic = questionSet.invokes.compactMap { (invocation) -> AdvanceLogic? in
                    switch invocation.behavior {
                    case .end:
                        return AdvanceLogic(criteria: invocation.criteria ?? .true, pageID: successPageID)

                    case .continue(let nextQuestionSetID):
                        return AdvanceLogic(criteria: invocation.criteria ?? .true, pageID: nextQuestionSetID)
                    }
                }

                let questionPage = Page(id: questionSet.id, questions: questions, advanceButtonLabel: questionSet.buttonTitle, pageIndicatorValue: index, advanceLogic: advanceLogic)

                pages[questionPage.id] = questionPage
            }
        }

        self.pages = pages

        self.rangeChoiceLabelNumberFormatter = NumberFormatter()
        self.isRequired = false
        self.validationErrorMessage = configuration.validationError

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

    internal var hasAnswer: Bool {
        return self.allQuestions.contains(where: { $0.hasAnswer })
    }

    internal var surveyIsOnLastPage: Bool {
        return self.currentPage.advanceLogic.count == 0
    }

    /// Sets the current question set and the question list with the new ones based on the selected answer.
    internal func advanceToNextPage() async throws {
        let nextPageID = try await self.interactionDelegate.getNextPageID(for: currentPage.advanceLogic)

        // Send response if there are no further question pages.
        if !self.surveyDidSendResponse && (nextPageID == nil || nextPageID == self.successPageID) {
            await self.sendResponse()
        }

        if let nextPageID = nextPageID {
            self.delegate?.surveyViewModelPageWillChange(self)
            self.currentPageID = nextPageID
            self.delegate?.surveyViewModelPageDidChange(self)

            self.currentPage.questions.forEach { self.visitedQuestionIDs.insert($0.questionID) }
        } else {
            self.delegate?.surveyViewModelDidFinish(self)
        }
    }

    internal func setNeedsUpdateValidation() {
        if self.shouldCoalesceValidationChanges {
            self.validationChanged = true
        } else {
            self.delegate?.surveyViewModelValidationDidChange(self)
        }
    }

    // MARK: - Private

    private var validationChanged = false
    private var shouldCoalesceValidationChanges = false

    private func coalesceValidationChanges(_ updateBlock: () -> Void) {
        self.validationChanged = false
        self.shouldCoalesceValidationChanges = true

        updateBlock()

        self.shouldCoalesceValidationChanges = false
    }

    private func sendResponse() async {
        for (questionID, responses) in self.response.questionResponses {
            await self.interactionDelegate.recordResponse(responses, for: questionID)
        }

        self.interactionDelegate.engage(event: .submit(from: self.interaction))
        await self.interactionDelegate.send(surveyResponse: self.response)

        self.surveyDidSendResponse = true
    }

    private static func buildQuestionViewModels(questions: [SurveyConfiguration.Question], requiredText: String?) -> [SurveyViewModel.Question] {
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

struct AdvanceLogic: Sendable {
    let criteria: Criteria
    let pageID: String?
}

extension Criteria {
    static let `true` = Criteria(subClauses: [])
}
