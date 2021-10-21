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
}
