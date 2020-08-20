//
//  SuveyViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class SurveyViewModelTests: XCTestCase, SurveyViewModelDelegate {
    var viewModel: SurveyViewModel?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUp() {
        guard let surveyURL = Bundle(for: type(of: self)).url(forResource: "Survey - 3.1", withExtension: "json"), let surveyData = try? Data(contentsOf: surveyURL) else {
            return XCTFail("Unable to load test survey data")
        }

        guard let surveyInteraction = try? JSONDecoder().decode(Interaction.self, from: surveyData) else {
            return XCTFail("Unable to decode test survey data")
        }

        if case let Interaction.InteractionConfiguration.survey(surveyConfiguration) = surveyInteraction.configuration {
            self.viewModel = SurveyViewModel(configuration: surveyConfiguration, surveyID: surveyInteraction.id)
            self.viewModel?.delegate = self
        }
    }

    func testSurveyMetadata() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.name, "Every Question Type")
        XCTAssertEqual(viewModel.submitButtonText, "Boom")
        XCTAssertEqual(viewModel.surveyID, "1")
        XCTAssertEqual(viewModel.validationErrorMessage, "You done goofed.")
        XCTAssertEqual(viewModel.introduction, "Please help us see how each question is formatted when returning a survey response to the server.")
        XCTAssertEqual(viewModel.thankYouMessage, "Thank you!")
        XCTAssertEqual(viewModel.isRequired, false)
        XCTAssertEqual(viewModel.questions.count, 16)

    }

    func testSurveyAnswers() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let freeformShortOptional = viewModel.questions[6] as? SurveyViewModel.FreeformQuestion,
            let freeformShortRequired = viewModel.questions[7] as? SurveyViewModel.FreeformQuestion,
            let freeformLongOptional = viewModel.questions[8] as? SurveyViewModel.FreeformQuestion,
            let freeformLongRequired = viewModel.questions[9] as? SurveyViewModel.FreeformQuestion
        else {
            return XCTFail("Freeform questions have non-freeform view models")
        }

        XCTAssertEqual(viewModel.response, [String: [SurveyQuestionResponse]]())

        freeformShortOptional.answerText = " "
        freeformShortRequired.answerText = "Foo"
        freeformLongOptional.answerText = "\n"
        freeformLongRequired.answerText = "Bar"

        XCTAssertEqual(
            viewModel.response,
            [
                "56e0b5d9c7199274f700001b": [SurveyQuestionResponse.freeform("Foo")],
                "56e0b5d9c7199274f700001d": [SurveyQuestionResponse.freeform("Bar")],
            ])
    }

    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel) {
        self.gotDidSubmit = true
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        self.gotValidationDidChange = true
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        self.gotSelectionDidChange = true
    }
}
