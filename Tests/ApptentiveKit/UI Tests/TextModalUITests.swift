//
//  TextModalUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 11/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

class TextModalUITests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testLaunch() throws {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal"].tap()

        XCTAssertTrue(XCUIApplication().staticTexts["Message Title"].exists)
        XCTAssertTrue(XCUIApplication().staticTexts["Message content."].exists)
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }
}
