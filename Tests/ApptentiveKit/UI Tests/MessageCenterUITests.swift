//
//  MessageCenterUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 10/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

class MessageCenterUITests: XCTestCase {
    override func setUp() {
        XCUIApplication().launch()
    }

    func testHappyPath() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()

        let _ = XCUIApplication().navigationBars["Message Center"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(XCUIApplication().navigationBars["Message Center"].exists, "Name should exist")
    }

    func testUIDocumentPicker() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()
        let attachmentButton = XCUIApplication().buttons["attachmentButton"]
        attachmentButton.tap()
        let filesButton = XCUIApplication().buttons["Files"]
        XCTAssertTrue(filesButton.exists)
        filesButton.tap()
        let predicate = NSPredicate(format: "label CONTAINS %@", "Recents")
        let documentPickerTitleText = XCUIApplication().staticTexts.containing(predicate).firstMatch
        XCTAssertTrue(documentPickerTitleText.waitForExistence(timeout: 10))

    }

    func testImagePicker() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()
        let attachmentButton = XCUIApplication().buttons["attachmentButton"]
        attachmentButton.tap()
        let imagesButton = XCUIApplication().buttons["Images"]
        XCTAssertTrue(imagesButton.exists)
        //        imagesButton.tap()
        //        let predicate = NSPredicate(format: "label CONTAINS %@", "Photos")
        //        let imagePickerText = XCUIApplication().staticTexts.containing(predicate).firstMatch
        //        XCTAssertTrue(imagePickerText.waitForExistence(timeout: 10))

    }
}
