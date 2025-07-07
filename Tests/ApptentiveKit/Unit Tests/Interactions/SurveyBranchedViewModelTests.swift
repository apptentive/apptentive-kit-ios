//
//  SurveyBranchedViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 7/12/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

@MainActor struct SurveyBranchedViewModelTests {

    var interaction: Interaction
    var interactionDelegate: SpyInteractionDelegate
    var viewModelDelegate: SpySurveyViewModelDelegate

    init() throws {
        self.interaction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranched")
        self.interactionDelegate = SpyInteractionDelegate()
        self.viewModelDelegate = SpySurveyViewModelDelegate()
    }

    @Test func testSurveyMetaData() throws {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            throw TestError(reason: "Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        #expect(viewModel.name == "How was your experience?")
        #expect(viewModel.termsAndConditions?.linkURL.absoluteString == "https://www.example.com/")
        #expect(viewModel.termsAndConditions?.linkLabel == "Terms & Conditions")
        #expect(viewModel.closeConfirmation.title == "Close Survey?")
        #expect(viewModel.closeConfirmation.message == "You will lose your progress if you close this survey.")
        #expect(viewModel.closeConfirmation.closeButtonTitle == "Close")
        #expect(viewModel.closeConfirmation.continueButtonTitle == "Back to Survey")
        #expect(viewModel.pageIndicatorSegmentCount == 8)
        #expect(String(viewModel.validationErrorMessage.characters) == "Error: Please fix your response to continue")
        #expect(viewModel.pages.count == 10)
    }

    @Test func testSurveyBranchedQuestionSets() throws {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            throw TestError(reason: "Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        let introPage = viewModel.pages["intro"]

        #expect(introPage?.description.flatMap { String($0.characters) } == "Please tell us about your experience with our survey builder.")
        #expect(introPage?.pageIndicatorValue == nil, "Intro question should have no segments highlighted.")

        let firstPage = viewModel.pages["question_set_1"]!
        let firstQuestion = firstPage.questions[0] as! SurveyViewModel.ChoiceQuestion
        let firstAnswerChoice = firstQuestion.choices[0]
        let secondAnswerChoice = firstQuestion.choices[1]

        #expect(firstPage.id == "question_set_1")
        #expect(firstPage.pageIndicatorValue == 0)
        #expect(firstPage.advanceLogic.count == 2)
        #expect(firstPage.questions.count == 1)
        #expect(firstQuestion.questionID == "question_1")
        #expect(String(firstQuestion.text.characters) == "Do you love our current survey building and management experience?")
        #expect(firstQuestion.choices.count == 2)
        #expect(firstQuestion.isRequired)
        #expect(firstQuestion.instructions == "select one")
        #expect(firstQuestion.errorMessage == "Error - There was a problem with your single-select answer.")

        #expect(firstQuestion.choices.count == 2)
        #expect(String(firstAnswerChoice.label.characters) == "Yes")
        #expect(!firstAnswerChoice.supportsOther)

        #expect(String(secondAnswerChoice.label.characters) == "No")
        #expect(!secondAnswerChoice.supportsOther)

        let secondPage = viewModel.pages["question_set_2"]!
        #expect(secondPage.id == "question_set_2")

        let lastPage = viewModel.pages["success"]!

        #expect(lastPage.pageIndicatorValue == nil)
        #expect(lastPage.description.flatMap { String($0.characters) } == "Thank you for your valuable time. Your feedback will be used to help us improve our features for you!")
    }

    @Test func testAdvanceToNextQuestionSet() async throws {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            throw TestError(reason: "Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        viewModel.delegate = self.viewModelDelegate

        try await viewModel.advanceToNextPage()

        #expect(viewModel.currentPageID == "question_set_1")

        viewModel.currentPageID = "question_set_8"

        try await viewModel.advanceToNextPage()

        #expect(self.viewModelDelegate.didSubmit)
    }

    @Test func testValidationDidChange() async throws {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            throw TestError(reason: "Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        viewModel.delegate = self.viewModelDelegate

        await viewModel.advance()

        await viewModel.advance()

        #expect(self.viewModelDelegate.validationDidChange)
    }

    @Test func testOpenTermsAndConditions() async {
        let url = URL(string: "https://github.com")!
        let _ = await self.interactionDelegate.open(url)
        #expect(self.interactionDelegate.openedURL == url)
    }

    @Test func testDisclaimerIntroPage() throws {
        let disclaimerNoIntroInteraction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranchedDisclaimerNoIntro")

        guard case .surveyV12(let configuration) = disclaimerNoIntroInteraction.configuration else {
            throw TestError(reason: "Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: disclaimerNoIntroInteraction, interactionDelegate: self.interactionDelegate)

        #expect(viewModel.currentPageID == "intro", "Should have an intro page even without intro (but with disclaimer)")
        #expect(viewModel.introduction == nil, "Introduction text should be nil for this interaction")
        #expect(viewModel.disclaimerText != nil, "Disclaimer text should not be nil for this interaction")
    }

    @Test func testNoDisclaimerNoIntroPage() throws {
        let disclaimerNoIntroInteraction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranchedNoIntro")

        guard case .surveyV12(let configuration) = disclaimerNoIntroInteraction.configuration else {
            throw TestError(reason: "Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: disclaimerNoIntroInteraction, interactionDelegate: self.interactionDelegate)

        #expect(viewModel.currentPageID != "intro")
        #expect(viewModel.disclaimerText == nil, "Disclaimer text should be nil for this interaction")
    }

    class SpySurveyViewModelDelegate: SurveyViewModelDelegate {
        var didSubmit = false
        var validationDidChange = false

        func surveyViewModelDidFinish(_ viewModel: SurveyViewModel) {
            self.didSubmit = true
        }

        func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
            self.validationDidChange = true
        }

        func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {}

        func surveyViewModelPageWillChange(_ viewModel: SurveyViewModel) {}

        func surveyViewModelPageDidChange(_ viewModel: SurveyViewModel) {
            self.didSubmit = true
        }
    }
}
