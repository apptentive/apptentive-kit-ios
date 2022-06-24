//
//  NavigateToLinkUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 12/2/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

class NavigateToLinkUITests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testHappyPath() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["http://www.apptentive.com"].tap()

        // let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")

        // This is causing problems in CI. Reevaluate once we migrate away from Travis.
        //        guard let connectionString = safari.buttons["URL"].value as? String else {
        //            return XCTFail("Can't get URL from Safari")
        //        }

        // TODO: figure out why comparison of connectionString doesn't work.
    }
}
