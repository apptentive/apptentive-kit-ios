//
//  NotImplementedAlertUITests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 12/8/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

class NotImplementedAlertUITests: XCTestCase {

    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testAlert() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables
        tablesQuery.staticTexts["Not Implemented"].tap()
        let alertsQuery = XCUIApplication().alerts["Interaction Presenter Error"]
        XCTAssertTrue(alertsQuery.exists)
        XCTAssertTrue(alertsQuery.buttons["OK"].exists)
        alertsQuery.buttons["OK"].tap()
        XCTAssertTrue(tablesQuery.staticTexts["Not Implemented"].exists)
    }
}
