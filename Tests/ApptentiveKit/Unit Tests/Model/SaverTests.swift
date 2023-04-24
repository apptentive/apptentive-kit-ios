//
//  SaverTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 3/17/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

final class SaverTests: XCTestCase {

    func testPlaintextConversationSaving() throws {
        let environment = MockEnvironment()
        let conversation = Conversation(environment: environment)
        let record = ConversationRoster.Record(state: .placeholder, path: UUID().uuidString)

        let containerURL = try environment.applicationSupportURL().appendingPathComponent(record.path)
        let saver = EncryptedPropertyListSaver<Conversation>(containerURL: containerURL, filename: "Conversation.B", fileManager: environment.fileManager, encryptionKey: nil)
        try environment.fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)

        try saver.save(conversation)

        let conversationFileURL = containerURL.appendingPathComponent("Conversation.B.plist")

        XCTAssertTrue(environment.fileManager.fileExists(atPath: conversationFileURL.path))

        let data = try Data(contentsOf: conversationFileURL)

        let decoder = PropertyListDecoder()
        let _ = try decoder.decode(Conversation.self, from: data)

        try MockEnvironment.cleanContainerURL()
    }

    func testEncryptedConversationSaving() throws {
        let environment = MockEnvironment()
        let conversation = Conversation(environment: environment)
        let record = ConversationRoster.Record(state: .placeholder, path: UUID().uuidString)
        let containerURL = try environment.applicationSupportURL().appendingPathComponent(record.path)
        let encryptionKey = Data(base64Encoded: "DSVDTuA285GBnfWtZXDvhHDxwpQkF1wq9ycl4WX1QQg=")!
        let saver = EncryptedPropertyListSaver<Conversation>(containerURL: containerURL, filename: "Conversation.B", fileManager: environment.fileManager, encryptionKey: encryptionKey)
        try environment.fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)

        try saver.save(conversation)

        let conversationFileURL = containerURL.appendingPathComponent("Conversation.B.plist.encrypted")

        XCTAssertTrue(environment.fileManager.fileExists(atPath: conversationFileURL.path))

        XCTAssertThrowsError(try PropertyListDecoder().decode(Conversation.self, from: Data(contentsOf: conversationFileURL)), "Should not be able to decode encrypted conversation") { error in
            if case Swift.DecodingError.dataCorrupted = error {
                // all good
            } else {
                XCTFail("Expected decoding error")
            }
        }

        let data = try Data(contentsOf: conversationFileURL).decrypted(with: encryptionKey)
        let decoder = PropertyListDecoder()
        let _ = try decoder.decode(Conversation.self, from: data)

        try MockEnvironment.cleanContainerURL()
    }
}
