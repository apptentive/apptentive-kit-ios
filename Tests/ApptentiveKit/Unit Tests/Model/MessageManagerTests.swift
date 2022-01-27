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
        self.messageManager.attachmentCacheURL = URL(string: "file:///tmp/")!
    }

    func testMergeMessages() {
        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpg", url: URL(string: "https://example.com/dog.jpg")!, size: 123)
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

        let merged = MessageManager.merge(existing, with: updated)

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

        let downloadedMessage = MessagesResponse.Message(id: "abc", nonce: "def", sentByLocalUser: false, body: "Body", attachments: [attachment], sender: sender, isHidden: false, isAutomated: false, sentDate: Date())

        let convertedMessage = MessageManager.convert(downloadedMessage: downloadedMessage)

        XCTAssertEqual(convertedMessage.nonce, "def")
        XCTAssertEqual(convertedMessage.status, .unread)
        XCTAssertEqual(convertedMessage.body, "Body")
        XCTAssertEqual(convertedMessage.attachments[0].contentType, attachment.contentType)
        XCTAssertEqual(convertedMessage.attachments[0].filename, attachment.filename)
        XCTAssertEqual(convertedMessage.attachments[0].url, attachment.url)
        XCTAssertEqual(convertedMessage.attachments[0].size, attachment.size)
        XCTAssertEqual(convertedMessage.sender?.name, sender.name)
        XCTAssertEqual(convertedMessage.sender?.profilePhoto, sender.profilePhoto)
    }

    func testConvertOutgoingMessage() {
        let attachment = Payload.Attachment(contentType: "image/jpeg", filename: "dog.jpg", contents: .file(URL(string: "file:///tmp/attachment.jpg")!))

        let outgoingMessage = OutgoingMessage(body: "Body", attachments: [attachment], customData: nil, isAutomated: false, isHidden: false)

        let convertedMessage = MessageManager.convert(outgoingMessage: outgoingMessage, nonce: "def", sentDate: Date())

        XCTAssertEqual(convertedMessage.nonce, "def")
        XCTAssertEqual(convertedMessage.status, .queued)
        XCTAssertEqual(convertedMessage.body, "Body")
        XCTAssertEqual(convertedMessage.attachments[0].contentType, attachment.contentType)
        XCTAssertEqual(convertedMessage.attachments[0].filename, attachment.filename)
        XCTAssertNil(convertedMessage.sender)
    }

    func testStatus() {
        let message0 = MessagesResponse.Message(id: "abc", nonce: "def", sentByLocalUser: false, body: "Body", attachments: [], sender: nil, isHidden: true, isAutomated: false, sentDate: Date())

        XCTAssertEqual(MessageManager.status(of: message0), .hidden)

        let message1 = MessagesResponse.Message(id: "abc", nonce: "def", sentByLocalUser: true, body: "Body", attachments: [], sender: nil, isHidden: false, isAutomated: true, sentDate: Date())

        XCTAssertEqual(MessageManager.status(of: message1), .automated)

        let message2 = MessagesResponse.Message(id: "abc", nonce: "def", sentByLocalUser: true, body: "Body", attachments: [], sender: nil, isHidden: false, isAutomated: false, sentDate: Date())

        XCTAssertEqual(MessageManager.status(of: message2), .sent)
    }

    func testSavingAndLoadingAttachmentToDisk() throws {
        let data = Data()
        if let fileURL = self.messageManager.createAttachmentURL(fileName: "Attachment 1", fileType: "image", nonce: UUID().uuidString, index: 0) {
            self.messageManager.saveAttachmentToDisk(payloadContents: nil, data: data, url: nil, fileURL: fileURL)
            self.messageManager.loadAttachmentURLAndData(fileURL: fileURL)
            if let url = self.messageManager.attachmentURLs.first?.key {
                XCTAssertTrue(url.absoluteString.contains("Attachment 1"))
            }
        }
    }

    func testCreatingFileURL() {
        if let fileURL = self.messageManager.createAttachmentURL(fileName: "Attachment 1", fileType: "image", nonce: UUID().uuidString, index: 0) {
            XCTAssertTrue(fileURL.absoluteString.contains("Attachment"))
        }
    }

}
