//
//  MessageCenter.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 9/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import ApptentiveKit

class MessageCenterTests: XCTestCase {

    var environment = MockEnvironment()
    var viewModel: MessageCenterViewModel?
    var spySender: SpyInteractionDelegate?

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "MessageCenter")
        guard case let Interaction.InteractionConfiguration.messageCenter(configuration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }
        self.spySender = SpyInteractionDelegate()
        self.viewModel = MessageCenterViewModel(configuration: configuration, interaction: interaction, delegate: self.spySender!)
    }

    func testMesssageCenterMetaData() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model.")
        }

        XCTAssertEqual(viewModel.headingTitle, "Message Center")
        XCTAssertEqual(viewModel.branding, "Powered By Apptentive")
        XCTAssertEqual(viewModel.composerTitle, "New Message")
        XCTAssertEqual(viewModel.greetingTitle, "Hello!")
        XCTAssertEqual(viewModel.statusBody, "We will respond to your message soon.")
        XCTAssertEqual(viewModel.automatedMessageBody, "We're sorry to hear that you don't love FooApp! Is there anything we could do to make it better?")
    }

    func testDecodingMessageList() throws {
        guard let directoryURL = Bundle(for: type(of: self)).url(forResource: "Test Interactions", withExtension: nil) else {
            return XCTFail("Unable to find test data")
        }

        let localFileManager = FileManager()

        let resourceKeys = Set<URLResourceKey>([.nameKey])
        let directoryEnumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: Array(resourceKeys))!

        for case let fileURL as URL in directoryEnumerator {
            if fileURL.absoluteString.contains("MessageList.json") {
                let data = try Data(contentsOf: fileURL)

                let _ = try JSONDecoder().decode(MessageList.self, from: data)
            }
        }
    }
    func testMessageListPersistence() {
        var url: URL?
        do {
            let containerURL = try self.environment.applicationSupportURL().appendingPathComponent("com.apptentive.feedback")
            url = containerURL
        } catch {
            NSLog("Error retreiving url: \(error)")
        }
        let data = CustomData()
        let messageList = MessageList(
            messages: [
                Message(
                    body: nil, attachments: [Message.Attachment(mediaType: "test", filename: "test", url: nil, data: nil)], isHidden: true, customData: data, id: nil, sentByLocalUser: true, isAutomated: true,
                    sender: Message.Sender(id: "test", name: nil, profilePhotoURL: nil), sentDate: Date())
            ], endsWith: nil, hasMore: true)
        let messageManager = MessageManager()
        messageManager.messageList = messageList

        if let url = url {
            messageManager.messageListRepository = MessageManager.createRepository(containerURL: url, filename: "", fileManager: FileManager.default)
            try? messageManager.saveMessagesToDisk()
            messageManager.messageList = nil
            do {
                let loadedMessages = try messageManager.messageListRepository?.load()
                if let message = loadedMessages?.messages {
                    XCTAssertNotNil(message)
                }
            } catch {
                NSLog("Error loading messages: \(error)")
            }
        }
    }

    func testGetMessage() {
        let message = Message(body: "Test", sentDate: Date())
        self.spySender?.messageManager?.messageList = MessageList(messages: [message], endsWith: nil, hasMore: false)

        self.spySender?.getMessages(completion: { messageManager in
            XCTAssertEqual(messageManager.messageList?.messages[0].body, "Test")
        })
    }
}
