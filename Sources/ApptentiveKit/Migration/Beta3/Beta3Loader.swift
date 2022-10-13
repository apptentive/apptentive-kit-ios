//
//  Beta3Loader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Beta3Loader: Loader {
    var containerURL: URL
    var environment: GlobalEnvironment

    init(containerURL: URL, environment: GlobalEnvironment) {
        self.containerURL = containerURL
        self.environment = environment
    }

    var conversationFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.conversationFileURL.path)
    }

    var payloadsFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.payloadsFileURL.path)
    }

    var messagesFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.messagesFileURL.path)
    }

    func loadConversation() throws -> Conversation {
        throw LoaderError.brokenVersion
    }

    func loadPayloads() throws -> [Payload] {
        throw LoaderError.brokenVersion
    }

    func loadMessages() throws -> MessageList? {
        throw LoaderError.brokenVersion
    }

    func cleanUp() throws {
        if self.conversationFileExists {
            try self.environment.fileManager.removeItem(at: self.conversationFileURL)
        }

        if self.payloadsFileExists {
            try self.environment.fileManager.removeItem(at: self.payloadsFileURL)
        }

        if self.messagesFileExists {
            try self.environment.fileManager.removeItem(at: self.messagesFileURL)
        }
    }

    private var conversationFileURL: URL {
        return self.containerURL.appendingPathComponent("Conversation.plist")
    }

    private var payloadsFileURL: URL {
        return self.containerURL.appendingPathComponent("PayloadQueue.plist")
    }

    private var messagesFileURL: URL {
        return self.containerURL.appendingPathComponent("MessageList.plist")
    }
}
