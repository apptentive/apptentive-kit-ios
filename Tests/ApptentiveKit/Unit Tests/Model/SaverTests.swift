//
//  SaverTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 3/17/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct SaverTests {
    @Test func testPlaintextConversationSaving() throws {
        let dataProvider = MockDataProvider()
        let conversation = Conversation(dataProvider: dataProvider)
        let record = ConversationRoster.Record(state: .placeholder, path: UUID().uuidString)
        let fileManager = FileManager.default

        let containerURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(record.path)
        let saver = EncryptedPropertyListSaver<Conversation>(containerURL: containerURL, filename: "Conversation.B", fileManager: fileManager, encryptionKey: nil)
        try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)

        try saver.save(conversation)

        let conversationFileURL = containerURL.appendingPathComponent("Conversation.B.plist")

        #expect(fileManager.fileExists(atPath: conversationFileURL.path))

        let data = try Data(contentsOf: conversationFileURL)

        let decoder = PropertyListDecoder()
        let _ = try decoder.decode(Conversation.self, from: data)

        Task {
            try await MockEnvironment.cleanContainerURL()
        }
    }

    @Test func testEncryptedConversationSaving() throws {
        let dataProvider = MockDataProvider()
        let conversation = Conversation(dataProvider: dataProvider)
        let record = ConversationRoster.Record(state: .placeholder, path: UUID().uuidString)
        let containerURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(record.path)
        let encryptionKey = Data(base64Encoded: "DSVDTuA285GBnfWtZXDvhHDxwpQkF1wq9ycl4WX1QQg=")!
        let fileManager = FileManager.default
        let saver = EncryptedPropertyListSaver<Conversation>(containerURL: containerURL, filename: "Conversation.B", fileManager: fileManager, encryptionKey: encryptionKey)
        try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true)

        try saver.save(conversation)

        let conversationFileURL = containerURL.appendingPathComponent("Conversation.B.plist.encrypted")

        #expect(fileManager.fileExists(atPath: conversationFileURL.path))

        #expect(throws: Swift.DecodingError.self, "Should not be able to decode encrypted conversation") {
            try PropertyListDecoder().decode(Conversation.self, from: Data(contentsOf: conversationFileURL))
        }

        let data = try Data(contentsOf: conversationFileURL).decrypted(with: encryptionKey)
        let decoder = PropertyListDecoder()
        let _ = try decoder.decode(Conversation.self, from: data)

        Task {
            try await MockEnvironment.cleanContainerURL()
        }
    }
}
