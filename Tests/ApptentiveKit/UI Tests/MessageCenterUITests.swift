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

        let _ = XCUIApplication().navigationBars["Message Center"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(XCUIApplication().navigationBars["Message Center"].exists, "Name should exist")

        let sendButton = app.buttons["sendButton"]
        let attachmentButton = app.buttons["attachmentButton"]
        let composeTextView = app.textViews["composeTextView"]

        XCTAssertFalse(sendButton.isEnabled)

        composeTextView.tap()
        app.typeText("Test Message")

        attachmentButton.tap()
        app.buttons["Images"].tap()

        app /*@START_MENU_TOKEN@*/.scrollViews.otherElements.images[
            "Photo, August 08, 2012, 2:55 PM"
        ] /*[[".otherElements[\"Photos\"].scrollViews.otherElements",".otherElements[\"Photo, March 30, 2018, 12:14 PM, Photo, August 08, 2012, 2:55 PM, Photo, August 08, 2012, 2:29 PM, Photo, August 08, 2012, 11:52 AM, Photo, October 09, 2009, 2:09 PM, Photo, March 12, 2011, 4:17 PM\"].images[\"Photo, August 08, 2012, 2:55 PM\"]",".images[\"Photo, August 08, 2012, 2:55 PM\"]",".scrollViews.otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
            .tap()
        app /*@START_MENU_TOKEN@*/.scrollViews.otherElements.images[
            "Photo, August 08, 2012, 2:29 PM"
        ] /*[[".otherElements[\"Photos\"].scrollViews.otherElements",".otherElements[\"Photo, March 30, 2018, 12:14 PM, Photo, August 08, 2012, 2:55 PM, Photo, August 08, 2012, 2:29 PM, Photo, August 08, 2012, 11:52 AM, Photo, October 09, 2009, 2:09 PM, Photo, March 12, 2011, 4:17 PM\"].images[\"Photo, August 08, 2012, 2:29 PM\"]",".images[\"Photo, August 08, 2012, 2:29 PM\"]",".scrollViews.otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
            .tap()
        app /*@START_MENU_TOKEN@*/.scrollViews.otherElements.images[
            "Photo, March 12, 2011, 4:17 PM"
        ] /*[[".otherElements[\"Photos\"].scrollViews.otherElements",".otherElements[\"Photo, March 30, 2018, 12:14 PM, Photo, August 08, 2012, 2:55 PM, Photo, August 08, 2012, 2:29 PM, Photo, August 08, 2012, 11:52 AM, Photo, October 09, 2009, 2:09 PM, Photo, March 12, 2011, 4:17 PM\"].images[\"Photo, March 12, 2011, 4:17 PM\"]",".images[\"Photo, March 12, 2011, 4:17 PM\"]",".scrollViews.otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
            .tap()
        app /*@START_MENU_TOKEN@*/.scrollViews.otherElements.images[
            "Photo, October 09, 2009, 2:09 PM"
        ] /*[[".otherElements[\"Photos\"].scrollViews.otherElements",".otherElements[\"Photo, March 30, 2018, 12:14 PM, Photo, August 08, 2012, 2:55 PM, Photo, August 08, 2012, 2:29 PM, Photo, August 08, 2012, 11:52 AM, Photo, October 09, 2009, 2:09 PM, Photo, March 12, 2011, 4:17 PM\"].images[\"Photo, October 09, 2009, 2:09 PM\"]",".images[\"Photo, October 09, 2009, 2:09 PM\"]",".scrollViews.otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
            .tap()

        app.navigationBars["Photos"].buttons["Add"].tap()

        if app.buttons["Remove IMG_0001.jpeg"].waitForExistence(timeout: 5.0) {
            app.buttons["Remove IMG_0001.jpeg"].tap()

            attachmentButton.tap()
            app.buttons["Files"].tap()
            app.buttons["Cancel"].tap()

            XCTAssertFalse(app.buttons["Remove IMG_0001.jpeg"].exists)

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

        let editProfileButton = XCUIApplication().navigationBars["Message Center"].buttons["Profile"]
        editProfileButton.tap()

        XCTAssertTrue(XCUIApplication().navigationBars["Profile"].exists)

        XCUIApplication().navigationBars["Profile"].buttons["Done"].tap()
        XCUIApplication().navigationBars["Message Center"].buttons["Close"].tap()

        tablesQuery.staticTexts["MessageCenterRequestEmail"].tap()
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

        let editProfileButton = XCUIApplication().navigationBars["Message Center"].buttons["Profile"]
        editProfileButton.tap()

        XCTAssertTrue(XCUIApplication().navigationBars["Profile"].exists)

        XCUIApplication().navigationBars["Profile"].buttons["Done"].tap()
        XCUIApplication().navigationBars["Message Center"].buttons["Close"].tap()

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

        let messageTextView = XCUIApplication().textViews["composeTextView"]
        messageTextView.tap()
        messageTextView.typeText("test")

        let sendButton = XCUIApplication().buttons["sendButton"]
        sendButton.tap()
    }
}
