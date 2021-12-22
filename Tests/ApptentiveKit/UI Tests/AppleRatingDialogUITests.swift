//
//  AppleRatingDialogUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 12/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

class AppleRatingDialogUITests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testHappyPath() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["AppleRatingDialog"].tap()

        // These checks seems to be unreliable in CI. We should revisit this when transitioning away from Travis.
        //XCTAssertTrue(XCUIApplication().otherElements["Rating"].exists)

        //XCUIApplication().buttons["Not Now"].tap()

        //XCTAssertTrue(tablesQuery.staticTexts["AppleRatingDialog"].exists)
    }
}
