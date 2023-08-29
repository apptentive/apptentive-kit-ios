//
//  MessageCenterUITests.swift
//  ApptentiveUITests
//
//  Created by Frank Schmitt on 10/21/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

class MessageCenterUITests: XCTestCase {
    override func setUp() {
        let app = XCUIApplication()
        app.launchArguments = ["-layerSpeed", "500"]
        app.launch()
    }

    func testHappyPath() {
        let app = XCUIApplication()
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()

        let _ = XCUIApplication().navigationBars["MessageCenter"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(XCUIApplication().navigationBars["MessageCenter"].exists, "Name should exist")

        let sendButton = app.buttons["sendButton"]
        let attachmentButton = app.buttons["attachmentButton"]
        let composeTextView = app.textViews["composeTextView"]

        XCTAssertFalse(sendButton.isEnabled)

        composeTextView.tap()
        app.typeText("Test Message")

        attachmentButton.tap()
        app.buttons["Images"].tap()

        let _ = app.staticTexts["Select up to 4 photos."].waitForExistence(timeout: 5)

        app.scrollViews.otherElements.images.element(boundBy: 0).tap()
        app.scrollViews.otherElements.images.element(boundBy: 1).tap()
        app.scrollViews.otherElements.images.element(boundBy: 2).tap()
        app.scrollViews.otherElements.images.element(boundBy: 3).tap()

        app.navigationBars["Photos"].buttons["Add"].tap()

        if app.buttons["Remove IMG_0003.jpeg"].waitForExistence(timeout: 5.0) {
            app.buttons["Remove IMG_0003.jpeg"].tap()

            attachmentButton.tap()
            app.buttons["Files"].tap()
            app.buttons["Cancel"].tap()

            XCTAssertFalse(app.buttons["Remove IMG_0003.jpeg"].exists)

            sendButton.tap()
        } else {
            XCTFail("Remove button didn't show up")
        }
    }
    func testUIDocumentPicker() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()
        let attachmentButton = XCUIApplication().buttons["attachmentButton"]
        attachmentButton.tap()
        let filesButton = XCUIApplication().buttons["Files"]
        XCTAssertTrue(filesButton.exists)
        filesButton.tap()
        let predicate = NSPredicate(format: "label CONTAINS %@", "Recents")
        let documentPickerTitleText = XCUIApplication().staticTexts.containing(predicate).firstMatch
        XCTAssertTrue(documentPickerTitleText.waitForExistence(timeout: 10))

    }

    func testImagePicker() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()
        let attachmentButton = XCUIApplication().buttons["attachmentButton"]
        attachmentButton.tap()
        let imagesButton = XCUIApplication().buttons["Images"]
        XCTAssertTrue(imagesButton.exists)
        imagesButton.tap()
        let predicate = NSPredicate(format: "label CONTAINS %@", "Photos")
        let imagePickerText = XCUIApplication().staticTexts.containing(predicate).firstMatch
        XCTAssertTrue(imagePickerText.waitForExistence(timeout: 10))
    }

    func testProfileViewBarButton() {
        XCUIApplication().activate()

        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()

        XCTAssertTrue(XCUIApplication().navigationBars.buttons.element(boundBy: 0).exists)
    }

    func testProfileRequired() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenterRequireEmail"].tap()
        let nameTextField = XCUIApplication().textFields["Name"]
        let emailTextField = XCUIApplication().textFields["Email"]

        nameTextField.tap()
        nameTextField.typeText("name")
        emailTextField.tap()
        emailTextField.typeText("test@email.com")

        let messageTextView = XCUIApplication().textViews["composeTextView"]
        messageTextView.tap()
        messageTextView.typeText("test")

        let sendButton = XCUIApplication().buttons["sendButton"]
        sendButton.tap()

        let editProfileButton = XCUIApplication().navigationBars["MessageCenterRequireEmail"].buttons["Profile"]
        editProfileButton.tap()

        XCTAssertTrue(XCUIApplication().navigationBars["Profile"].exists)

        XCUIApplication().navigationBars["Profile"].buttons["Done"].tap()
        XCUIApplication().navigationBars["MessageCenterRequireEmail"].buttons["Close"].tap()

        tablesQuery.staticTexts["MessageCenterRequireEmail"].tap()
        XCTAssertFalse(XCUIApplication().textFields["Name"].exists)
        XCTAssertFalse(XCUIApplication().textFields["Email"].exists)
    }

    func testProfileRequested() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenterRequestEmail"].tap()
        let nameTextField = XCUIApplication().textFields["Name"]
        let emailTextField = XCUIApplication().textFields["Email"]

        nameTextField.tap()
        nameTextField.typeText("name")
        emailTextField.tap()
        emailTextField.typeText("test@email.com")

        let messageTextView = XCUIApplication().textViews["composeTextView"]
        messageTextView.tap()
        messageTextView.typeText("test")

        let sendButton = XCUIApplication().buttons["sendButton"]
        sendButton.tap()

        let editProfileButton = XCUIApplication().navigationBars["MessageCenterRequestEmail"].buttons["Profile"]
        editProfileButton.tap()

        XCTAssertTrue(XCUIApplication().navigationBars["Profile"].exists)

        XCUIApplication().navigationBars["Profile"].buttons["Done"].tap()
        XCUIApplication().navigationBars["MessageCenterRequestEmail"].buttons["Close"].tap()

        tablesQuery.staticTexts["MessageCenterRequestEmail"].tap()
        XCTAssertFalse(XCUIApplication().textFields["Name"].exists)
        XCTAssertFalse(XCUIApplication().textFields["Email"].exists)
    }

    func testEditProfileHidden() {
        XCUIApplication().activate()
        let tablesQuery = XCUIApplication().tables

        tablesQuery.staticTexts["MessageCenter"].tap()
        XCTAssertFalse(XCUIApplication().textFields["Name"].exists)
        XCTAssertFalse(XCUIApplication().textFields["Email"].exists)

        XCTAssertTrue(XCUIApplication().textViews["We're sorry to hear that you don't love FooApp! Is there anything we could do to make it better?"].exists)

        let messageTextView = XCUIApplication().textViews["composeTextView"]
        messageTextView.tap()
        messageTextView.typeText("test")

        let sendButton = XCUIApplication().buttons["sendButton"]
        sendButton.tap()
    }
}
