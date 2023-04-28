//
//  SurveyBranchedViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 7/12/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class SurveyBranchedViewModelTests: XCTestCase {

    var interaction: Interaction!
    var interactionDelegate: SpyInteractionDelegate!
    var viewModelDelegate: SpySurveyViewModelDelegate!

    override func setUpWithError() throws {
        self.interaction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranched")
        self.interactionDelegate = SpyInteractionDelegate()
        self.viewModelDelegate = SpySurveyViewModelDelegate()
    }

    func testSurveyMetaData() throws {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            return XCTFail("Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        XCTAssertEqual(viewModel.name, "How was your experience?")
        XCTAssertEqual(viewModel.termsAndConditions?.linkURL.absoluteString, "https://www.example.com/")
        XCTAssertEqual(viewModel.termsAndConditions?.linkLabel, "Terms & Conditions")
        XCTAssertEqual(viewModel.closeConfirmation.title, "Close Survey?")
        XCTAssertEqual(viewModel.closeConfirmation.message, "You will lose your progress if you close this survey.")
        XCTAssertEqual(viewModel.closeConfirmation.closeButtonTitle, "Close")
        XCTAssertEqual(viewModel.closeConfirmation.continueButtonTitle, "Back to Survey")
        XCTAssertEqual(viewModel.pageIndicatorSegmentCount, 8)
        XCTAssertEqual(viewModel.validationErrorMessage, "Error: Please fix your response to continue")
        XCTAssertTrue(viewModel.pages.count == 10)
    }

    func testSurveyBranchedQuestionSets() {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            return XCTFail("Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        let introPage = viewModel.pages["intro"]

        XCTAssertEqual(introPage?.description, "Please tell us about your experience with our survey builder.")
        XCTAssertEqual(introPage?.pageIndicatorValue, nil, "Intro question should have no segments highlighted.")

        let firstPage = viewModel.pages["question_set_1"]!
        let firstQuestion = firstPage.questions[0] as! SurveyViewModel.ChoiceQuestion
        let firstAnswerChoice = firstQuestion.choices[0]
        let secondAnswerChoice = firstQuestion.choices[1]

        XCTAssertEqual(firstPage.id, "question_set_1")
        XCTAssertEqual(firstPage.pageIndicatorValue, 0)
        XCTAssertTrue(firstPage.advanceLogic.count == 2)
        XCTAssertTrue(firstPage.questions.count == 1)
        XCTAssertEqual(firstQuestion.questionID, "question_1")
        XCTAssertEqual(firstQuestion.text, "Do you love our current survey building and management experience?")
        XCTAssertEqual(firstQuestion.choices.count, 2)
        XCTAssertEqual(firstQuestion.isRequired, true)
        XCTAssertEqual(firstQuestion.instructions, "select one")
        XCTAssertEqual(firstQuestion.errorMessage, "Error - There was a problem with your single-select answer.")

        XCTAssertTrue(firstQuestion.choices.count == 2)
        XCTAssertEqual(firstAnswerChoice.label, "Yes")
        XCTAssertEqual(firstAnswerChoice.supportsOther, false)

        XCTAssertEqual(secondAnswerChoice.label, "No")
        XCTAssertEqual(secondAnswerChoice.supportsOther, false)

        let secondPage = viewModel.pages["question_set_2"]!
        XCTAssertEqual(secondPage.id, "question_set_2")

        let lastPage = viewModel.pages["success"]!

        XCTAssertNil(lastPage.pageIndicatorValue)
        XCTAssertEqual(lastPage.description, "Thank you for your valuable time. Your feedback will be used to help us improve our features for you!")
    }

    func testAdvanceToNextQuestionSet() {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            return XCTFail("Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        viewModel.delegate = self.viewModelDelegate

        viewModel.advanceToNextPage()

        let expectation1 = self.expectation(description: "Wait for survey to advance")

        DispatchQueue.main.async {
            XCTAssertEqual(viewModel.currentPageID, "question_set_1")

            expectation1.fulfill()
        }

        viewModel.currentPageID = "question_set_8"

        let expectation2 = self.expectation(description: "Wait for survey to finish")

        viewModel.advanceToNextPage()

        DispatchQueue.main.async {
            XCTAssertTrue(self.viewModelDelegate.didSubmit)

            expectation2.fulfill()
        }

        self.wait(for: [expectation1, expectation2], timeout: 5.0)
    }

    func testValidationDidChange() {
        guard case .surveyV12(let configuration) = self.interaction.configuration else {
            return XCTFail("Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: self.interaction, interactionDelegate: self.interactionDelegate)

        viewModel.delegate = self.viewModelDelegate

        viewModel.advance()

        let expectation = self.expectation(description: "View model advances once, then fails validation")

        DispatchQueue.main.async {
            viewModel.advance()

            XCTAssertTrue(self.viewModelDelegate.validationDidChange)

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1.0)
    }

    func testOpenTermsAndConditions() {
        let url = URL(string: "https://github.com")!
        self.interactionDelegate.open(url) { _ in }
        XCTAssertTrue(self.interactionDelegate.openedURL == url)
    }

    func testDisclaimerIntroPage() throws {
        let disclaimerNoIntroInteraction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranchedDisclaimerNoIntro")

        guard case .surveyV12(let configuration) = disclaimerNoIntroInteraction.configuration else {
            return XCTFail("Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: disclaimerNoIntroInteraction, interactionDelegate: self.interactionDelegate)

        XCTAssertEqual(viewModel.currentPageID, "intro", "Should have an intro page even without intro (but with disclaimer)")
        XCTAssertNil(viewModel.introduction, "Introduction text should be nil for this interaction")
        XCTAssertNotNil(viewModel.disclaimerText, "Disclaimer text should not be nil for this interaction")
    }

    func testNoDisclaimerNoIntroPage() throws {
        let disclaimerNoIntroInteraction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranchedNoIntro")

        guard case .surveyV12(let configuration) = disclaimerNoIntroInteraction.configuration else {
            return XCTFail("Interaction configuration should be survey branched configuration")
        }

        let viewModel = SurveyViewModel(configuration: configuration, interaction: disclaimerNoIntroInteraction, interactionDelegate: self.interactionDelegate)

        XCTAssertNotEqual(viewModel.currentPageID, "intro")
        XCTAssertNil(viewModel.disclaimerText, "Disclaimer text should not be nil for this interaction")
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
