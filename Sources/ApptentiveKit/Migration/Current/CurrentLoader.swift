//
//  CurrentLoader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

struct CurrentLoader: Loader {
    private static let rosterFilename = "Roster.B"
    static let conversationFilename = "Conversation.B"
    private static let payloadsFilename = "PayloadQueue.B"
    static let messagesFilename = "MessageList.B"
    private static let resourceDirectoryName = "Resources.B"
    private static let fileExtension = "plist"

    static func rosterFilename(for appCredentials: Apptentive.AppCredentials) -> String {
        return "\(self.rosterFilename).\(appCredentials.key)"
    }

    static func payloadsFilename(for appCredentials: Apptentive.AppCredentials) -> String {
        return "\(self.payloadsFilename).\(appCredentials.key)"
    }

    static func conversationFilePath(for record: ConversationRoster.Record) -> String {
        return "\(record.path)/\(self.conversationFilename).\(self.fileExtension)"
    }

    static func messagesFilePath(for record: ConversationRoster.Record) -> String {
        return "\(record.path)/\(self.messagesFilename).\(self.fileExtension)"
    }

    static func resourceDirectoryName(for appCredentials: Apptentive.AppCredentials) -> String {
        return "\(self.resourceDirectoryName).\(appCredentials.key)"
    }

    static let loaderChain: [Loader.Type] = [CurrentLoader.self, ALoader.self, Beta3Loader.self, LegacyLoader.self, FreshLoader.self]

    static func loadLatestVersion(context: LoaderContext, loadingBlock: @escaping (Loader) throws -> ConversationRoster) throws -> ConversationRoster {
        for LoaderType in Self.loaderChain {
            let loader = LoaderType.init(context: context)

            do {
                if loader.rosterFileExists {
                    let result = try loadingBlock(loader)

                    do {
                        try loader.cleanUpRoster()
                    } catch let error {
                        Logger.default.error("Error removing extraneous files for version \(String(describing: LoaderType)): \(error)")
                    }

                    return result
                }
            } catch let error {
                Logger.default.error("Error loading conversation from version \(String(describing: LoaderType)): \(error)")
            }
        }

        throw ApptentiveError.internalInconsistency
    }

    static func loadLatestVersion(
        for record: ConversationRoster.Record, context: LoaderContext, loadingBlock: @escaping (Loader) throws -> Void
    ) throws {
        for LoaderType in Self.loaderChain {
            let loader = LoaderType.init(context: context)

            do {
                if loader.conversationFileExists(for: record) {
                    try loadingBlock(loader)

                    do {
                        try loader.cleanUp(for: record)
                    } catch let error {
                        Logger.default.error("Error removing extraneous files for version \(String(describing: LoaderType)): \(error)")
                    }

                    return
                }
            } catch let error {
                Logger.default.error("Error loading conversation from version \(String(describing: LoaderType)): \(error)")
            }
        }

        throw ApptentiveError.internalInconsistency
    }

    let context: LoaderContext
    let decoder = PropertyListDecoder()

    init(context: LoaderContext) {
        self.context = context
    }

    var rosterFileExists: Bool {
        return self.context.fileManager.fileExists(atPath: self.conversationRosterURL.path)
    }

    func conversationFileExists(for record: ConversationRoster.Record) -> Bool {
        return self.context.fileManager.fileExists(atPath: self.conversationFileURL(for: record).path)
    }

    func loadRoster() throws -> ConversationRoster {
        let data = try Data(contentsOf: self.conversationRosterURL)
        return try self.decoder.decode(ConversationRoster.self, from: data)
    }

    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation {
        var data = try Data(contentsOf: self.conversationFileURL(for: record))

        if case .loggedIn(credentials: _, subject: _, encryptionKey: let encryptionKey) = record.state {
            data = try data.decrypted(with: encryptionKey)
        }

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

    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList? {
        if self.messagesFileExists(for: record) {
            var data = try Data(contentsOf: self.messagesFileURL(for: record))

            if case .loggedIn(credentials: _, subject: _, encryptionKey: let encryptionKey) = record.state {
                data = try data.decrypted(with: encryptionKey)
            }

            return try self.decoder.decode(MessageList.self, from: data)
        } else {
            return nil
        }
    }

    func cleanUpRoster() throws {
        // Don't delete anything from the current version.
    }

    func cleanUp(for record: ConversationRoster.Record) throws {
        // Don't delete anything from the current version.
    }

    private var conversationRosterURL: URL {
        return self.context.containerURL.appendingPathComponent(Self.rosterFilename(for: self.context.appCredentials)).appendingPathExtension(Self.fileExtension)
    }

    private func conversationFileURL(for record: ConversationRoster.Record) -> URL {
        let result = self.context.containerURL.appendingPathComponent(Self.conversationFilePath(for: record))

        if let _ = record.encryptionKey {
            return result.appendingPathExtension("encrypted")
        } else {
            return result
        }
    }

    private var payloadsFileURL: URL {
        return self.context.containerURL.appendingPathComponent(Self.payloadsFilename(for: self.context.appCredentials)).appendingPathExtension(Self.fileExtension)
    }

    private func messagesFileURL(for record: ConversationRoster.Record) -> URL {
        let result = self.context.containerURL.appendingPathComponent(Self.messagesFilePath(for: record))

        if let _ = record.encryptionKey {
            return result.appendingPathExtension("encrypted")
        } else {
            return result
        }
    }

    private var payloadsFileExists: Bool {
        return self.context.fileManager.fileExists(atPath: self.payloadsFileURL.path)
    }

    private func messagesFileExists(for record: ConversationRoster.Record) -> Bool {
        return self.context.fileManager.fileExists(atPath: self.messagesFileURL(for: record).path)
    }
}
