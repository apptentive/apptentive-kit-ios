//
//  CurrentLoader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct CurrentLoader: Loader {
    static let conversationFilename = "Conversation.A"
    static let payloadsFilename = "PayloadQueue.A"
    static let messagesFilename = "MessageList.A"
    static let fileExtension = "plist"

    static func loadLatestVersion(containerURL: URL, environment: GlobalEnvironment, completion: @escaping (Loader) throws -> Void) {
        let loaderChain: [Loader.Type] = [CurrentLoader.self, Beta3Loader.self, LegacyLoader.self]

        for LoaderType in loaderChain {
            let loader = LoaderType.init(containerURL: containerURL, environment: environment)

            do {
                if loader.conversationFileExists {
                    try completion(loader)

                    return
                }
            } catch let error {
                ApptentiveLogger.default.error("Error loading conversation from version \(String(describing: LoaderType)): \(error)")
            }

            do {
                try loader.cleanUp()
            } catch let error {
                ApptentiveLogger.default.error("Error removing extraneous files for version \(String(describing: LoaderType)): \(error)")
            }
        }
    }

    var containerURL: URL
    var environment: GlobalEnvironment
    let decoder = PropertyListDecoder()

    init(containerURL: URL, environment: GlobalEnvironment) {
        self.containerURL = containerURL
        self.environment = environment
    }

    var conversationFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.conversationFileURL.path)
    }

    func loadConversation() throws -> Conversation {
        let data = try Data(contentsOf: self.conversationFileURL)
        return try self.decoder.decode(Conversation.self, from: data)
    }

    func loadPayloads() throws -> [Payload] {
        if self.payloadsFileExists {
            let data = try Data(contentsOf: self.payloadsFileURL)
            return try self.decoder.decode([Payload].self, from: data)
        } else {
            return []
        }
    }

    func loadMessages() throws -> MessageList? {
        if self.messagesFileExists {
            let data = try Data(contentsOf: self.messagesFileURL)
            return try self.decoder.decode(MessageList.self, from: data)
        } else {
            return nil
        }
    }

    func cleanUp() throws {
        // Don't delete anything from the current version.
    }

    private var conversationFileURL: URL {
        return self.containerURL.appendingPathComponent(Self.conversationFilename).appendingPathExtension(Self.fileExtension)
    }

    private var payloadsFileURL: URL {
        return self.containerURL.appendingPathComponent(Self.payloadsFilename).appendingPathExtension(Self.fileExtension)
    }

    private var messagesFileURL: URL {
        return self.containerURL.appendingPathComponent(Self.messagesFilename).appendingPathExtension(Self.fileExtension)
    }

    private var payloadsFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.payloadsFileURL.path)
    }

    private var messagesFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.messagesFileURL.path)
    }
}
