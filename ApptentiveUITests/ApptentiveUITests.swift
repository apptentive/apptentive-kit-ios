//
//  ApptentiveUITests.swift
//  ApptentiveUITests
//
//  Created by Apptentive on 3/3/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import XCTest

class ApptentiveUITests: XCTestCase {
    
    func testPresentLoveDialogWithConfiguration() {
        let app = XCUIApplication()
        app.launch()
        
        XCUIApplication().tables.staticTexts["Present Love Dialog with Configuration"].tap()
        
        let loveDialogTitle = "Do you love ApptentiveUITestsApp?"
        let loveDialogAffirmativeText = "Yup"
        
        XCTAssert(app.staticTexts[loveDialogTitle].exists, "should build prompt with default app name")
        XCTAssert(app.buttons[loveDialogAffirmativeText].exists, "should use valid custom argument instead of default")
        XCTAssert(app.buttons["Not Yet"].exists, "should use default if given a blank string")
        
        app.buttons[loveDialogAffirmativeText].tap()
        
        XCTAssertFalse(app.staticTexts[loveDialogTitle].exists, "should dismiss the love dialog")
    }
}
