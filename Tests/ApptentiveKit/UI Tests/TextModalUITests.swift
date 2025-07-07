//
//  TextModalUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 11/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@MainActor class TextModalUITests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testLaunch() throws {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal"].tap()

        let titleText = XCUIApplication().staticTexts["DialogTitleText"].label
        let messageText = XCUIApplication().staticTexts["DialogMessageText"].label

        XCTAssertEqual(titleText, "Message Title")
        XCTAssertEqual(messageText, "Message content.")

        XCTAssertTrue(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertEqual(XCUIApplication().images["DialogHeaderImageView"].label, "Disney Logo")
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }

    func testOnlyTitle() {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal - Title Only"].tap()
        let titleText = XCUIApplication().staticTexts["DialogTitleText"].label

        XCTAssertEqual(titleText, "Message Title")
        XCTAssertFalse(XCUIApplication().textViews["DialogMessageText"].exists)

        XCTAssertFalse(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)

    }

    func testOnlyMessage() {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal - Message Only"].tap()
        let messageText = XCUIApplication().staticTexts["DialogMessageText"].label

        XCTAssertEqual(messageText, "Message content.")
        XCTAssertFalse(XCUIApplication().textViews["DialogTitleText"].exists)

        XCTAssertFalse(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }

    func testOnlyImage() {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal - Image Only"].tap()

        XCTAssertFalse(XCUIApplication().textViews["DialogMessageText"].exists)
        XCTAssertFalse(XCUIApplication().textViews["DialogTitleText"].exists)

        let _ = XCUIApplication().images["DialogHeaderImageView"].waitForExistence(timeout: 5)

        XCTAssertTrue(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertEqual(XCUIApplication().images["DialogHeaderImageView"].label, "Disney Logo")
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }

    func testImageWithTitleHidden() {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal - Image w/ Only Body"].tap()
        let messageText = XCUIApplication().staticTexts["DialogMessageText"].label

        XCTAssertFalse(XCUIApplication().textViews["DialogTitleText"].exists)
        XCTAssertEqual(messageText, "Message content.")

        XCTAssertTrue(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertEqual(XCUIApplication().images["DialogHeaderImageView"].label, "Disney Logo")
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }

    func testImageWithMessageHidden() {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal - Image w/ Only Title"].tap()
        let titleText = XCUIApplication().staticTexts["DialogTitleText"].label

        XCTAssertFalse(XCUIApplication().staticTexts["DialogMessageText"].exists)
        XCTAssertEqual(titleText, "Message Title")

        XCTAssertTrue(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertEqual(XCUIApplication().images["DialogHeaderImageView"].label, "Disney Logo")
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }

    func testNoImageNoBodyNoTitle() {
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["TextModal - No Image/No Title/No Body"].tap()

        XCTAssertFalse(XCUIApplication().staticTexts["DialogTitleText"].exists)
        XCTAssertFalse(XCUIApplication().staticTexts["DialogMessageText"].exists)

        XCTAssertFalse(XCUIApplication().images["DialogHeaderImageView"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Message Center"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Survey"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Link"].exists)
        XCTAssertTrue(XCUIApplication().buttons["Dismiss"].exists)
        XCTAssertEqual(XCUIApplication().buttons.count, 4)

        XCUIApplication().buttons["Dismiss"].tap()

        XCTAssertTrue(tablesQuery.staticTexts["TextModal"].exists)
    }
}
