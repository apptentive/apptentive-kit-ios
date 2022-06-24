//
//  EnjoymentDialogUITests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

class EnjoymentDialogUITests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testHappyPath() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["Do you love this app?"].tap()

        let alertsQuery = XCUIApplication().alerts["Do you love this app?"]

        XCTAssertTrue(alertsQuery.exists)
        XCTAssertTrue(alertsQuery.buttons["Yes"].exists)
        XCTAssertTrue(alertsQuery.buttons["No"].exists)

        alertsQuery.buttons["Yes"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["Do you love this app?"].exists)
    }
}
