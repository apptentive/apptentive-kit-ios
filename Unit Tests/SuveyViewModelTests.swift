//
//  SuveyViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class SurveyViewModelTests: XCTestCase {
    var viewModel: SurveyViewModel?

    override func setUp() {
        guard let surveyURL = Bundle(for: type(of: self)).url(forResource: "Survey - 3.1", withExtension: "json"), let surveyData = try? Data(contentsOf: surveyURL) else {
            return XCTFail("Unable to load test survey data")
        }

        guard let surveyInteraction = try? JSONDecoder().decode(Interaction.self, from: surveyData) else {
            return XCTFail("Unable to decode test survey data")
        }

        self.viewModel = SurveyViewModel(interaction: surveyInteraction)
    }

    func testSurveyMetadata() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.title, "(copy) All Combos Survey")
        XCTAssertEqual(viewModel.submitButtonText, "Boom")
        XCTAssertEqual(viewModel.surveyID, "1")
        XCTAssertEqual(viewModel.validationErrorMessage, "You done goofed.")
        XCTAssertEqual(viewModel.introduction, "Please help us see how each question is formatted when returning a survey response to the server.")
        XCTAssertEqual(viewModel.thankYouMessage, "Thank you!")
        XCTAssertEqual(viewModel.shouldShowThankYou, true)
        XCTAssertEqual(viewModel.required, false)
        XCTAssertEqual(viewModel.questions.count, 10)

    }

    func testSurveyQuestionBasics() {
        guard let questions = self.viewModel?.questions else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(questions[0].text, "Multichoice Optional")
        XCTAssertEqual(questions[0].instructionsText, "select one")

        XCTAssertEqual(questions[1].text, "Multichoice Required")
        XCTAssertEqual(questions[1].instructionsText, "Mandatory—select one")
    }
}
