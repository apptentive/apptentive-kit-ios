//
//  SurveyBranchedUITests.swift
//  ApptentiveUITests
//
//  Created by Luqmaan Khan on 8/1/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import XCTest

class SurveyBranchedUITests: XCTestCase {

    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testHidngAndShowingTermsAndConditionsWhenKeyboardAppears() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["Survey-Building Experience"].tap()

        let startButton = XCUIApplication().windows.element(boundBy: 1).descendants(matching: .button).staticTexts["Start"]
        startButton.tap()

        let termsAndConditions = XCUIApplication().windows.element(boundBy: 1).descendants(matching: .button).staticTexts["Terms & Conditions"]
        XCTAssertTrue(termsAndConditions.exists)

        tablesQuery.staticTexts["Yes"].tap()

        let nextButton = XCUIApplication().windows.element(boundBy: 1).descendants(matching: .button).staticTexts["Next"]
        nextButton.tap()

        tablesQuery.staticTexts["Other"].tap()

        XCTAssertTrue(!termsAndConditions.exists)

        tablesQuery.staticTexts["Other"].tap()

        XCTAssertTrue(termsAndConditions.waitForExistence(timeout: 10))
    }

}
