//
//  SurveyUITests.swift
//  SurveyUITests
//
//  Created by Frank Schmitt on 3/3/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import XCTest

class SurveyUITests: XCTestCase {

    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testHappyPath() {
        ApptentiveNavigationController.prefersLargeHeader = false

        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["Survey"] /*[[".cells.staticTexts[\"Survey\"]",".staticTexts[\"Survey\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let _ = XCUIApplication().navigationBars["Every Question Type"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(XCUIApplication().navigationBars["Every Question Type"].firstMatch.exists, "Name should exist")
        XCTAssertTrue(XCUIApplication().staticTexts["Please help us see how each question is formatted when returning a survey response to the server."].exists, "Introduction should exist")

        XCTAssertTrue(tablesQuery.otherElements["Multichoice Optional . select one"].exists, "First questions title should exist")

        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["1A"] /*[[".cells.staticTexts[\"1A\"]",".staticTexts[\"1A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["3A"] /*[[".cells.staticTexts[\"3A\"]",".staticTexts[\"3A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["4B"] /*[[".cells.staticTexts[\"4B\"]",".staticTexts[\"4B\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["5A"] /*[[".cells.staticTexts[\"5A\"]",".staticTexts[\"5A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["6A"] /*[[".cells.staticTexts[\"6A\"]",".staticTexts[\"6A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let textField = tablesQuery.textFields["6"]
        textField.tap()
        textField.typeText("Foo\n")

        let textView = tablesQuery.textViews["8"]
        textView.tap()
        textView.typeText("Bar")

        tablesQuery.buttons["Boom"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["Thank you!"].exists, "Thank you text is displayed")

        XCTAssertTrue(tablesQuery.staticTexts["Survey"].waitForExistence(timeout: 5), "Survey dismisses if it's valid")
    }

    func testRadioQuestion() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["Survey"] /*[[".cells.staticTexts[\"Survey\"]",".staticTexts[\"Survey\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let oneA = tablesQuery.cells.containing(.staticText, identifier: "1A").firstMatch
        let oneB = tablesQuery.cells.containing(.staticText, identifier: "1B").firstMatch

        XCTAssertFalse(oneA.isSelected, "No radio buttons selected at first")
        XCTAssertFalse(oneB.isSelected, "No radio buttons selected at first")

        oneA.tap()
        XCTAssertTrue(oneA.isSelected, "Radio button is selected after tap")
        oneA.tap()
        XCTAssertTrue(oneA.isSelected, "Selected radio button is not deselected after tap")

        oneB.tap()
        XCTAssertTrue(oneB.isSelected, "Other radio button is selected after tap")
        XCTAssertFalse(oneA.isSelected, "First radio button is deselected after tap on other one")
    }

    func testRangeQuestion() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["SurveyRange"].tap()

        // Due to a quirk in UISegmentedControl, we have to muck with the accessibility features
        // to a point where the UI tests don't work anymore.
        // At some point we'll be using a custom control and can re-enable these.
        //        XCTAssertTrue(XCUIApplication().segmentedControls.buttons["10"].firstMatch.exists, "There should be a 10 button")
        //
        //        let npsSurvey10 = XCUIApplication().segmentedControls.buttons["10"].firstMatch
        //        XCTAssertFalse(npsSurvey10.isSelected, "No segment selected at first.")
        //
        //        npsSurvey10.tap()
        //        XCTAssertTrue(npsSurvey10.isSelected, "NPS 10 should be selected")
        //
        //        let missingMinMaxSurvey10 = XCUIApplication().segmentedControls.buttons.matching(identifier: "10").element(boundBy: 1)
        //        XCTAssertFalse(missingMinMaxSurvey10.isSelected, "No segment selected at first.")
        //
        //        missingMinMaxSurvey10.tap()
        //        XCTAssertTrue(missingMinMaxSurvey10.isSelected,  "10 should be selected")
        //
        //        // Make sure this is still selected
        //        XCTAssertTrue(npsSurvey10.isSelected, "10 should still be selected")
    }

    func testCheckboxQuestion() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery /*@START_MENU_TOKEN@*/.staticTexts["Survey"] /*[[".cells.staticTexts[\"Survey\"]",".staticTexts[\"Survey\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let threeA = tablesQuery.cells.containing(.staticText, identifier: "3A").firstMatch
        let threeB = tablesQuery.cells.containing(.staticText, identifier: "3B").firstMatch

        XCTAssertFalse(threeA.isSelected, "No checkboxes selected at first")
        XCTAssertFalse(threeB.isSelected, "No checkboxes selected at first")

        threeA.tap()
        XCTAssertTrue(threeA.isSelected, "Checkbox is selected after tap")
        threeA.tap()
        XCTAssertFalse(threeA.isSelected, "Checkbox radio is deselected after tap")

        threeB.tap()
        threeA.tap()
        XCTAssertTrue(threeB.isSelected, "Other checkbox is selected after tap")
        XCTAssertTrue(threeA.isSelected, "First checkbox is also selected after tap")
    }

    func testFailedValidation() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["Survey"].tap()
        tablesQuery.buttons["Boom"].tap()

        //TODO: Remove this comment in order to test failed validation based on error message
        //XCTAssertTrue(XCUIApplication().otherElements["Error - There was a problem with your multi-select answer."].exists, "Error message should exist.")
        XCTAssertTrue(XCUIApplication().navigationBars["Every Question Type"].firstMatch.exists, "Survey doesn't dismiss if it's not valid")

    }

    func testOtherQuestion() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["Survey"].tap()
        let otherCell = tablesQuery.cells.containing(.staticText, identifier: "Other").firstMatch
        XCTAssertFalse(otherCell.isSelected, "Other option not setelcted at first.")

        otherCell.tap()
        XCTAssertTrue(otherCell.isSelected, "Other cell is selected after tap.")

        let otherTextField = XCUIApplication().textFields["OtherCell"]
        XCTAssertTrue(otherTextField.exists)

        let threeA = tablesQuery.cells.containing(.staticText, identifier: "1A").firstMatch
        threeA.tap()
        XCTAssertFalse(otherTextField.isHittable)
    }

    func testTermsOfService() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables
        tablesQuery.staticTexts["Survey"].tap()
        let toolbar = XCUIApplication().toolbars
        let termsOfServiceBarButtonItem = toolbar.buttons["Terms and Conditions"]
        XCTAssertTrue(termsOfServiceBarButtonItem.exists, "The ToS button is not showing.")
        termsOfServiceBarButtonItem.tap()
        let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
        XCTAssertTrue(safari.wait(for: .runningForeground, timeout: 5))
    }
}
