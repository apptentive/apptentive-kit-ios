//
//  ApptentiveUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 3/3/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

class ApptentiveUITests: XCTestCase {
    override func setUp() {
        XCUIApplication().launch()
    }

    //    func testHappyPath() {
    //        let tablesQuery = XCUIApplication().tables
    //
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Survey"]/*[[".cells.staticTexts[\"Survey\"]",".staticTexts[\"Survey\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //
    //        XCTAssertTrue(XCUIApplication().navigationBars["Every Question Type"].exists, "Name should exist")
    //        XCTAssertTrue(XCUIApplication().staticTexts["Please help us see how each question is formatted when returning a survey response to the server."].exists, "Introduction should exist")
    //
    //        XCTAssertTrue(tablesQuery.otherElements["Multichoice Optional"].exists, "First questions title should exist")
    //        XCTAssertTrue(tablesQuery.otherElements["select one"].exists, "First question's instructions should exist")
    //
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["1A"]/*[[".cells.staticTexts[\"1A\"]",".staticTexts[\"1A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["3A"]/*[[".cells.staticTexts[\"3A\"]",".staticTexts[\"3A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["4B"]/*[[".cells.staticTexts[\"4B\"]",".staticTexts[\"4B\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["5A"]/*[[".cells.staticTexts[\"5A\"]",".staticTexts[\"5A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["6A"]/*[[".cells.staticTexts[\"6A\"]",".staticTexts[\"6A\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //
    //        let textField = tablesQuery.textFields["6"]
    //        textField.tap()
    //        textField.typeText("Foo")
    //
    //        let textView = tablesQuery.textViews["8"]
    //        textView.tap()
    //        textView.typeText("Bar")
    //
    //        tablesQuery.buttons["Boom"].tap()
    //
    //        XCTAssertTrue(tablesQuery.staticTexts["Thank you!"].exists, "Thank you text is displayed")
    //
    //        XCTAssertTrue(tablesQuery.staticTexts["Survey"].waitForExistence(timeout: 5), "Survey dismisses if it's valid")
    //    }
    //
    //    func testRadioQuestion() {
    //        let tablesQuery = XCUIApplication().tables
    //
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Survey"]/*[[".cells.staticTexts[\"Survey\"]",".staticTexts[\"Survey\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //
    //        let oneA = tablesQuery.cells.containing(.staticText, identifier: "1A").firstMatch
    //        let oneB = tablesQuery.cells.containing(.staticText, identifier: "1B").firstMatch
    //
    //        XCTAssertFalse(oneA.isSelected, "No radio buttons selected at first")
    //        XCTAssertFalse(oneB.isSelected, "No radio buttons selected at first")
    //
    //        oneA.tap()
    //        XCTAssertTrue(oneA.isSelected, "Radio button is selected after tap")
    //        oneA.tap()
    //        XCTAssertTrue(oneA.isSelected, "Selected radio button is not deselected after tap")
    //
    //        oneB.tap()
    //        XCTAssertTrue(oneB.isSelected, "Other radio button is selected after tap")
    //        XCTAssertFalse(oneA.isSelected, "First radio button is deselected after tap on other one")
    //    }
    //
    //    func testCheckboxQuestion() {
    //        let tablesQuery = XCUIApplication().tables
    //
    //        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Survey"]/*[[".cells.staticTexts[\"Survey\"]",".staticTexts[\"Survey\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    //
    //        let threeA = tablesQuery.cells.containing(.staticText, identifier: "3A").firstMatch
    //        let threeB = tablesQuery.cells.containing(.staticText, identifier: "3B").firstMatch
    //
    //        XCTAssertFalse(threeA.isSelected, "No checkboxes selected at first")
    //        XCTAssertFalse(threeB.isSelected, "No checkboxes selected at first")
    //
    //        threeA.tap()
    //        XCTAssertTrue(threeA.isSelected, "Checkbox is selected after tap")
    //        threeA.tap()
    //        XCTAssertFalse(threeA.isSelected, "Checkbox radio is deselected after tap")
    //
    //        threeB.tap()
    //        threeA.tap()
    //        XCTAssertTrue(threeB.isSelected, "Other checkbox is selected after tap")
    //        XCTAssertTrue(threeA.isSelected, "First checkbox is also selected after tap")
    //    }
    //
    //    func testFailedValidation() {
    //        let tablesQuery = XCUIApplication().tables
    //
    //        tablesQuery.staticTexts["Survey"].tap()
    //        tablesQuery.buttons["Boom"].tap()
    //
    //        XCTAssertTrue(XCUIApplication().navigationBars["Every Question Type"].exists, "Survey doesn't dismiss if it's not valid")
    //    }
}
