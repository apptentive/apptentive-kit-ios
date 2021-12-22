//
//  BackgroundTests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 12/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

class BackgroundTests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testBackgroundForeground() {
        XCUIDevice.shared.press(.home)

        XCUIApplication().launch()
    }
}
