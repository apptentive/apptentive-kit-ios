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
        let messageList = MessageList(messages: [Message(body: nil, attachments: [Message.Attachment(mediaType: "test", filename: "test", data: nil, url: nil)], isHidden: true, customData: data, id: nil, isInbound: true, isAutomated: true, sender: Message.Sender(id: "test", name: nil, profilePhotoURL: nil))], endsWith: nil, hasMore: true)
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
}
