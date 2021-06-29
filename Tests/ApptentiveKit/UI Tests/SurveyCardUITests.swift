//
//  SurveyCardUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 6/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

class SurveyCardUITests: XCTestCase {

    override func setUpWithError() throws {
        XCUIApplication().launch()

        XCUIApplication().tables.staticTexts["SurveyCard"].tap()
    }

    func testHappyPath() throws {
        let _ = XCUIApplication().navigationBars["Every Question Type"].waitForExistence(timeout: 2.0)

        XCTAssertTrue(XCUIApplication().navigationBars["Every Question Type"].exists, "Name should exist")
        XCTAssertTrue(XCUIApplication().staticTexts["Please help us see how each question is formatted when returning a survey response to the server."].exists, "Introduction should exist")

        XCTAssertTrue(XCUIApplication().staticTexts["Multichoice Optional"].exists, "First question title should exist")

        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Multiselect Optional"].waitForExistence(timeout: 2.0), "Second question title should exist")

        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Multiselect Required"].waitForExistence(timeout: 2.0), "Third question title should exist")

        XCUIApplication().buttons["4B"].tap()
        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Multiselect Optional With Limits"].waitForExistence(timeout: 2.0), "Fourth question title should exist")

        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Multiselect Required With Limits"].waitForExistence(timeout: 2.0), "Fifth question title should exist")

        XCUIApplication().buttons["6B"].tap()
        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Singleline Short Optional"].waitForExistence(timeout: 2.0), "Sixth question title should exist")

        // The following will need a solution to the keyboard blocking the Next/Submit button.
        // Commenting out for now.
        //        XCUIApplication().keyboards.firstMatch.buttons["Next"].firstMatch.tap()
        //
        //        XCTAssertTrue(XCUIApplication().staticTexts["Singleline Short Required"].waitForExistence(timeout: 2.0), "Seventh question title should exist")
        //
        //        let textField = XCUIApplication().textFields["8"]
        //        textField.tap()
        //        textField.typeText("Test\n")
        //
        //        XCTAssertTrue(XCUIApplication().staticTexts["Singleline Long Optional"].waitForExistence(timeout: 2.0), "Eighth question title should exist")
        //
        //        XCUIApplication().keyboards.firstMatch.swipeDown()
        //        XCUIApplication().buttons["Next"].tap()
        //
        //        XCTAssertTrue(XCUIApplication().staticTexts["Singleline Long Required"].waitForExistence(timeout: 2.0), "Ninth question title should exist")
        //
        //        let textView = XCUIApplication().textViews["9"]
        //        textView.tap()
        //        textView.typeText("Test")
        //
        //        XCUIApplication().keyboards.firstMatch.swipeDown()
        //
        //        XCUIApplication().buttons["Submit"].tap()
    }

    func testFailedValidation() throws {
        let _ = XCUIApplication().navigationBars["Every Question Type"].waitForExistence(timeout: 2.0)

        XCTAssertTrue(XCUIApplication().staticTexts["Multichoice Optional"].exists, "First question title should exist")

        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Multiselect Optional"].waitForExistence(timeout: 2.0), "Second question title should exist")

        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Multiselect Required"].waitForExistence(timeout: 2.0), "Third question title should exist")

        XCUIApplication().buttons["Next"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Error - There was a problem with your multi-select answer."].waitForExistence(timeout: 2.0), "Third question title should exist")
    }
}
