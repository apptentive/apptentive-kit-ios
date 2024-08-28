//
//  Beta3Loader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Beta3Loader: Loader {
    let context: LoaderContext

    init(context: LoaderContext) {
        self.context = context
    }

    var rosterFileExists: Bool {
        return self.context.fileManager.fileExists(atPath: self.commonConversationFileURL.path)
    }

    func conversationFileExists(for record: ConversationRoster.Record) -> Bool {
        return self.context.fileManager.fileExists(atPath: self.conversationFileURL.path)
    }

    var payloadsFileExists: Bool {
        return self.context.fileManager.fileExists(atPath: self.payloadsFileURL.path)
    }

    var messagesFileExists: Bool {
        return self.context.fileManager.fileExists(atPath: self.messagesFileURL.path)
    }

    func loadRoster() throws -> ConversationRoster {
        try self.cleanUpRoster()

        throw LoaderError.brokenVersion
    }

    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation {
        try self.cleanUp(for: record)

        throw LoaderError.brokenVersion
    }

    func loadPayloads() throws -> [Payload] {
        throw LoaderError.brokenVersion
    }

    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList? {
        throw LoaderError.brokenVersion
    }

    func cleanUpRoster() throws {
        if self.payloadsFileExists {
            try self.context.fileManager.removeItem(at: self.payloadsFileURL)
        }
    }

    func cleanUp(for record: ConversationRoster.Record) throws {
        if self.conversationFileExists(for: record) {
            try self.context.fileManager.removeItem(at: self.conversationFileURL)
        }

        if self.messagesFileExists {
            try self.context.fileManager.removeItem(at: self.messagesFileURL)
        }
    }

    private var commonConversationFileURL: URL {
        return self.context.containerURL.appendingPathComponent("Conversation.plist")
    }

    private var conversationFileURL: URL {
        return self.context.containerURL.appendingPathComponent("Conversation.plist")
    }

    private var payloadsFileURL: URL {
        return self.context.containerURL.appendingPathComponent("PayloadQueue.plist")
    }

    private var messagesFileURL: URL {
        return self.context.containerURL.appendingPathComponent("MessageList.plist")
    }
}
