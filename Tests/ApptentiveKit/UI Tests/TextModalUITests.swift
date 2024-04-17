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
        if let titleText = XCUIApplication().textViews["DialogTitleText"].value as? String, let messageText = XCUIApplication().textViews["DialogMessageText"].value as? String {
            XCTAssertEqual(titleText, "Message Title")
            XCTAssertEqual(messageText, "Message content.")
        }

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
        if let titleText = XCUIApplication().textViews["DialogTitleText"].value as? String {
            XCTAssertEqual(titleText, "Message Title")
            XCTAssertFalse(XCUIApplication().textViews["DialogMessageText"].exists)
        }

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
        if let messageText = XCUIApplication().textViews["DialogMessageText"].value as? String {
            XCTAssertEqual(messageText, "Message content.")
            XCTAssertFalse(XCUIApplication().textViews["DialogTitleText"].exists)
        }

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
        if let messageText = XCUIApplication().textViews["DialogMessageText"].value as? String {
            XCTAssertFalse(XCUIApplication().textViews["DialogTitleText"].exists)
            XCTAssertEqual(messageText, "Message content.")
        }

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
        if let titleText = XCUIApplication().textViews["DialogTitleText"].value as? String {
            XCTAssertFalse(XCUIApplication().textViews["DialogMessageText"].exists)
            XCTAssertEqual(titleText, "Message Title")
        }

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

        if let titleText = XCUIApplication().textViews["DialogTitleText"].value as? String, let messageText = XCUIApplication().textViews["DialogMessageText"].value as? String {
            XCTAssertTrue(titleText.isEmpty)
            XCTAssertTrue(messageText.isEmpty)
        }

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
