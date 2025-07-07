//
//  MessageManagerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 1/13/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

struct MessageManagerTests {
    var messageManager: MessageManager!

    init() {
        self.messageManager = MessageManager(notificationCenter: NotificationCenter.default)
    }

    @Test func testPrepareDraftMessageForSending() async throws {
        await #expect(throws: Error.self) {
            let _ = try await self.messageManager.prepareDraftMessageForSending()
        }

        var customData = CustomData()
        customData["String"] = "string"

        await self.messageManager.setDraftMessageBody("Hey")
        await self.messageManager.setCustomData(customData)

        let result = try await self.messageManager.prepareDraftMessageForSending()
        #expect(result.0.body == "Hey")
        #expect(result.1 == customData)

        let bodyAfterSending = await self.messageManager.draftMessage.body
        let customDataAfterSending = await self.messageManager.customData

        #expect(bodyAfterSending == nil)
        #expect(customDataAfterSending == nil)
    }

    @Test func testPrepareAutomatedMessageForSending() async throws {
        var automatedMessage = await self.messageManager.automatedMessage
        #expect(automatedMessage == nil)

        await self.messageManager.setAutomatedMessageBody("Automated message body.")

        automatedMessage = await self.messageManager.automatedMessage
        #expect(automatedMessage?.body == "Automated message body.")
        #expect(automatedMessage?.isAutomated == true)

        automatedMessage = try await self.messageManager.prepareAutomatedMessageForSending()
        let formerAutomatedMessage = await self.messageManager.automatedMessage
        #expect(formerAutomatedMessage == nil, "Automated message is cleared after sending first message.")

        #expect(automatedMessage?.body == "Automated message body.")
        #expect(automatedMessage?.isAutomated == true)
    }

    @Test func testAddQueuedMessage() async {
        await self.messageManager.addQueuedMessage(MessageList.Message(nonce: "def456", sentDate: Date.distantPast, status: .draft), with: "abc123")

        let message = await self.messageManager.messages.last

        // Nonce, sentDate, and status should be updated.
        #expect(message?.nonce == "abc123")
        #expect(abs((message?.sentDate.timeIntervalSince1970)! - Date().timeIntervalSince1970) < 1.0)
        #expect(message?.status == .queued)
    }

    @Test func testMergeMessages() {
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

        let merged = MessageManager.merge(existing, with: updated, attachmentManager: nil, fileManager: FileManager.default)

        #expect(merged.count == 4)
        #expect(merged[0].nonce == "abc")
        #expect(merged[1].nonce == "def")
        #expect(merged[2].nonce == "ghi")
        #expect(merged[3].nonce == "jkl")

        #expect(merged[0].body == "Hey")
        #expect(merged[1].body == nil)
        #expect(merged[2].body == "Yo")
        #expect(merged[3].body == "Sup?")

        #expect(merged[0].attachments == [])
        #expect(merged[1].attachments == [attachment])
        #expect(merged[2].attachments == [])
        #expect(merged[3].attachments == [])

        #expect(merged[0].sender == nil)
        #expect(merged[1].sender == sender)
        #expect(merged[2].sender == nil)
        #expect(merged[3].sender == sender)

        #expect(merged[0].status == .sent)
        #expect(merged[1].status == .read)
        #expect(merged[2].status == .sent)
        #expect(merged[3].status == .unread)
    }

    @Test func testConvertDownloadedMessage() {
        let attachment = MessagesResponse.Message.Attachment(contentType: "image/jpeg", filename: "dog.jpg", url: URL(string: "https://example.com/dog.jpg")!, size: 123)
        let sender = MessagesResponse.Message.Sender(name: "Testy McTestface", profilePhoto: URL(string: "https://example.com/avi.jpg")!)

        let downloadedMessage = MessagesResponse.Message(id: "abc", nonce: "def", sentFromDevice: false, body: "Body", attachments: [attachment], sender: sender, isHidden: false, isAutomated: false, sentDate: Date())

        let convertedMessage = MessageManager.convert(downloadedMessage: downloadedMessage)

        #expect(convertedMessage.id == "abc")
        #expect(convertedMessage.nonce == "def")
        #expect(convertedMessage.status == .unread)
        #expect(convertedMessage.body == "Body")
        #expect(convertedMessage.attachments[0].contentType == attachment.contentType)
        #expect(convertedMessage.attachments[0].filename == attachment.filename)
        #expect(convertedMessage.attachments[0].storage == .remote(attachment.url, size: 123))
        #expect(convertedMessage.sender?.name == sender.name)
        #expect(convertedMessage.sender?.profilePhoto == sender.profilePhoto)
    }

    @Test func testStatus() {
        let message1 = MessagesResponse.Message(id: "abc", nonce: "def", sentFromDevice: false, body: "Body", attachments: [], sender: nil, isHidden: false, isAutomated: false, sentDate: Date())

        #expect(MessageManager.status(of: message1) == .unread)

        let message2 = MessagesResponse.Message(id: "abc", nonce: "def", sentFromDevice: true, body: "Body", attachments: [], sender: nil, isHidden: false, isAutomated: false, sentDate: Date())

        #expect(MessageManager.status(of: message2) == .sent)
    }

    @Test func testNewDraftMessage() {
        let draft = MessageManager.newDraftMessage()

        #expect(draft.nonce == "draft")
        #expect(draft.status == .draft)
    }
}
