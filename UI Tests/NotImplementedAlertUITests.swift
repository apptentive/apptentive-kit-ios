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
        XCUIApplication().launch()
    }
    
    func testAlert() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables
        tablesQuery.staticTexts["FakeInteraction"].tap()
        let alertsQuery = XCUIApplication().alerts["Interaction Presenter Error"]
        XCTAssertTrue(alertsQuery.exists)
        XCTAssertTrue(alertsQuery.buttons["Ok"].exists)
        alertsQuery.buttons["Ok"].tap()
        XCTAssertTrue(tablesQuery.staticTexts["FakeInteraction"].exists)
    }
}
