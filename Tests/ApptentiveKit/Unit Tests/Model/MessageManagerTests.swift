//
//  MessageManagerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 1/13/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class MessageManagerTests: XCTestCase {
    var messageManager: MessageManager!

    override func setUp() {
        self.messageManager = MessageManager(notificationCenter: NotificationCenter.default)
    }

    func testPrepareDraftMessageForSending() throws {
        XCTAssertThrowsError(try self.messageManager.prepareDraftMessageForSending())

        var customData = CustomData()
        customData["String"] = "string"

        self.messageManager.draftMessage.body = "Hey"
        self.messageManager.customData = customData

        let result = try self.messageManager.prepareDraftMessageForSending()
        XCTAssertEqual(result.0.body, "Hey")
        XCTAssertEqual(result.1, customData)

        XCTAssertNil(self.messageManager.draftMessage.body)
        XCTAssertNil(self.messageManager.customData)
    }

    func testPrepareAutomatedMessageForSending() throws {
        XCTAssertNil(self.messageManager.automatedMessage)

        self.messageManager.setAutomatedMessageBody("Automated message body.")

        XCTAssertEqual(self.messageManager.automatedMessage?.body, "Automated message body.")
        XCTAssertEqual(self.messageManager.automatedMessage?.isAutomated, true)

        let automatedMessage = try self.messageManager.prepareAutomatedMessageForSending()
        XCTAssertNil(self.messageManager.automatedMessage, "Automated message is cleared after sending first message.")

        XCTAssertEqual(automatedMessage?.body, "Automated message body.")
        XCTAssertEqual(automatedMessage?.isAutomated, true)
    }

    func testAddQueuedMessage() {
        self.messageManager.addQueuedMessage(MessageList.Message(nonce: "def456", sentDate: Date.distantPast, status: .draft), with: "abc123")

        let message = self.messageManager.messages.last

        // Nonce, sentDate, and status should be updated.
        XCTAssertEqual(message?.nonce, "abc123")
        XCTAssertEqual((message?.sentDate.timeIntervalSince1970)!, Date().timeIntervalSince1970, accuracy: 1.0)
        XCTAssertEqual(message?.status, .queued)
    }

    func testMergeMessages() {
        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpg", storage: .remote(URL(string: "https://example.com/dog.jpg")!, size: 123))
        let sender = MessageList.Message.Sender(name: "Testy McTestface", profilePhoto: URL(string: "https://example.com/avi.jpg")!)

        let dates: [Date] = [
            Date().addingTimeInterval(-400),
            Date().addingTimeInterval(-300),
            Date().addingTimeInterval(-200),
            Date().addingTimeInterval(-100),
        ]

        let existing: [MessageList.Message] = [
            .init(nonce: "abc", body: "Hey", attachments: [], sender: nil, sentDate: dates[0], status: .sent),
            .init(nonce: "def", body: nil, attachments: [attachment], sender: sender, sentDate: dates[1], status: .read),
            .init(nonce: "ghi", body: "Yo", attachments: [], sender: nil, sentDate: dates[2], status: .sent),
        ]

        let updated: [MessageList.Message] = [
            .init(nonce: "abc", body: "Hey", attachments: [], sender: nil, sentDate: dates[0], status: .sent),
            .init(nonce: "def", body: nil, attachments: [attachment], sender: sender, sentDate: dates[1], status: .unread),
            .init(nonce: "jkl", body: "Sup?", attachments: [], sender: sender, sentDate: dates[3], status: .unread),
        ]

        let merged = MessageManager.merge(existing, with: updated, attachmentManager: nil)

        XCTAssertEqual(merged.count, 4)

        XCTAssertEqual(merged[0].nonce, "abc")
        XCTAssertEqual(merged[1].nonce, "def")
        XCTAssertEqual(merged[2].nonce, "ghi")
        XCTAssertEqual(merged[3].nonce, "jkl")

        XCTAssertEqual(merged[0].body, "Hey")
        XCTAssertNil(merged[1].body)
        XCTAssertEqual(merged[2].body, "Yo")
        XCTAssertEqual(merged[3].body, "Sup?")

        XCTAssertEqual(merged[0].attachments, [])
        XCTAssertEqual(merged[1].attachments, [attachment])
        XCTAssertEqual(merged[2].attachments, [])
        XCTAssertEqual(merged[3].attachments, [])

        XCTAssertNil(merged[0].sender)
        XCTAssertEqual(merged[1].sender, sender)
        XCTAssertNil(merged[2].sender)
        XCTAssertEqual(merged[3].sender, sender)

        XCTAssertEqual(merged[0].status, .sent)
        XCTAssertEqual(merged[1].status, .read)
        XCTAssertEqual(merged[2].status, .sent)
        XCTAssertEqual(merged[3].status, .unread)
    }

    func testConvertDownloadedMessage() {
        let attachment = MessagesResponse.Message.Attachment(contentType: "image/jpeg", filename: "dog.jpg", url: URL(string: "https://example.com/dog.jpg")!, size: 123)
        let sender = MessagesResponse.Message.Sender(name: "Testy McTestface", profilePhoto: URL(string: "https://example.com/avi.jpg")!)

        let downloadedMessage = MessagesResponse.Message(id: "abc", nonce: "def", sentFromDevice: false, body: "Body", attachments: [attachment], sender: sender, isHidden: false, isAutomated: false, sentDate: Date())

        let convertedMessage = MessageManager.convert(downloadedMessage: downloadedMessage)

        XCTAssertEqual(convertedMessage.id, "abc")
        XCTAssertEqual(convertedMessage.nonce, "def")
        XCTAssertEqual(convertedMessage.status, .unread)
        XCTAssertEqual(convertedMessage.body, "Body")
        XCTAssertEqual(convertedMessage.attachments[0].contentType, attachment.contentType)
        XCTAssertEqual(convertedMessage.attachments[0].filename, attachment.filename)
        XCTAssertEqual(convertedMessage.attachments[0].storage, .remote(attachment.url, size: 123))
        XCTAssertEqual(convertedMessage.sender?.name, sender.name)
        XCTAssertEqual(convertedMessage.sender?.profilePhoto, sender.profilePhoto)
    }

    func testStatus() {
        let message1 = MessagesResponse.Message(id: "abc", nonce: "def", sentFromDevice: false, body: "Body", attachments: [], sender: nil, isHidden: false, isAutomated: false, sentDate: Date())

        XCTAssertEqual(MessageManager.status(of: message1), .unread)

        let message2 = MessagesResponse.Message(id: "abc", nonce: "def", sentFromDevice: true, body: "Body", attachments: [], sender: nil, isHidden: false, isAutomated: false, sentDate: Date())

        XCTAssertEqual(MessageManager.status(of: message2), .sent)
    }

    func testNewDraftMessage() {
        let draft = MessageManager.newDraftMessage()

        XCTAssertEqual(draft.nonce, "draft")
        XCTAssertEqual(draft.status, .draft)
    }
}
