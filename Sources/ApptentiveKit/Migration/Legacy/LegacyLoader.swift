//
//  LegacyLoader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

final class LegacyLoader: NSObject, Loader {
    let context: LoaderContext

    required init(context: LoaderContext) {
        self.context = context
    }

    var rosterFileExists: Bool {
        return self.context.fileManager.fileExists(atPath: self.metadataURL.path)
    }

    func conversationFileExists(for record: ConversationRoster.Record) -> Bool {
        return self.context.fileManager.fileExists(atPath: self.conversationFileURL(for: record).path)
    }

    func loadRoster(with _: SecureTokenStoring) throws -> ConversationRoster {
        let data = try Data(contentsOf: self.metadataURL)
        guard let legacyConversationMetadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversationMetadata.self, from: data) else {
            throw LoaderError.unreadableLegacyMetadata
        }

        var activeRecord: ConversationRoster.Record? = nil

        // Look for an anonymous conversation's metadata item.
        if let activeItem = legacyConversationMetadata.items.first(where: { $0.state != .loggedOut && $0.state != .undefined }),
            let directory = activeItem.directoryName
        {
            let state: ConversationRoster.Record.State = try {
                switch (activeItem.state, activeItem.identifier, activeItem.jwt, activeItem.userID, activeItem.encryptionKey) {
                case (.anonymousPending, _, _, _, _):
                    return .anonymousPending

                case (.legacyPending, _, .some(let token), _, _):
                    return .legacyPending(legacyToken: token)

                case (.anonymous, .some(let id), .some(let token), _, _):
                    return .anonymous(credentials: .init(id: id, token: token))

                case (.loggedIn, .some(let id), .some(let token), .some(let userID), .some(let encryptionKey)):
                    return .loggedIn(credentials: .init(id: id, token: token), subject: userID, encryptionKey: encryptionKey)

                case (.loggedOut, .some(let id), _, .some(let userID), _):
                    return .loggedOut(id: id, subject: userID)

                default:
                    apptentiveCriticalError("Error migrating active legacy metadata item \(String(describing: activeItem)).")
                    throw LoaderError.unreadableLegacyMetadata
                }
            }()

            activeRecord = ConversationRoster.Record(state: state, path: directory)
        }

        let loggedOutRecords: [ConversationRoster.Record] = legacyConversationMetadata.items.filter({ $0.state == .loggedOut }).compactMap { loggedOutItem in
            guard let directory = loggedOutItem.directoryName, let id = loggedOutItem.identifier, let userID = loggedOutItem.userID else {
                apptentiveCriticalError("Error migrating logged-out legacy metadata item \(String(describing: loggedOutItem)).")
                return nil
            }

            return ConversationRoster.Record(state: .loggedOut(id: id, subject: userID), path: directory)
        }

        return ConversationRoster(active: activeRecord, loggedOut: loggedOutRecords)
    }

    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation {
        let conversationData = try Data(contentsOf: self.conversationFileURL(for: record))

        var legacyConversation: LegacyConversation?

        NSKeyedUnarchiver.setClass(LegacyConversation.self, forClassName: "ApptentiveConversation")

        if case .loggedIn(credentials: _, subject: _, encryptionKey: let encryptionKey) = record.state {
            legacyConversation = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversation.self, from: conversationData.decrypted(with: encryptionKey))
        } else {
            legacyConversation = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversation.self, from: conversationData)
        }

        var newConversation = Conversation(dataProvider: self.context.dataProvider)

        // Copy over iteraction metrics if possible.
        if let legacyInteractions = legacyConversation?.engagement?.interactions {
            newConversation.interactions = EngagementMetrics(legacyMetrics: legacyInteractions)
        } else {
            throw ApptentiveError.internalInconsistency
        }

        // Copy over code point metrics if possible.
        if let legacyCodePoints = legacyConversation?.engagement?.codePoints {
            newConversation.codePoints = EngagementMetrics(legacyMetrics: legacyCodePoints)
        } else {
            throw ApptentiveError.internalInconsistency
        }

        // Copy over person data if possible.
        newConversation.person.name = legacyConversation?.person?.name
        newConversation.person.emailAddress = legacyConversation?.person?.emailAddress
        newConversation.person.mParticleID = legacyConversation?.person?.mParticleID
        newConversation.person.customData = Apptentive.convertLegacyCustomData(legacyConversation?.person?.customData)

        // Copy over device (custom data) if possible.
        newConversation.device.customData = Apptentive.convertLegacyCustomData(legacyConversation?.device?.customData)

        // Copy over random values if possible.
        newConversation.random.values = legacyConversation?.random?.randomValues ?? [:]

        return newConversation
    }

    func loadPayloads() throws -> [Payload] {
        // Not trying to migrate these as it would involve standing up a whole Core Data stack.
        return []
    }

    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList? {
        try self.context.fileManager.createDirectory(at: self.context.cacheURL, withIntermediateDirectories: true)

        // These are also complicated to migrate and can just be re-downloaded.
        return nil
    }

    func cleanUpRoster() throws {
        // Until we're out of beta, keep the legacy conversation around.
        // if self.rosterFileExists {
        //     try self.environment.fileManager.removeItem(at: self.metadataURL)
        // }
    }

    func cleanUp(for record: ConversationRoster.Record) throws {
        //        if self.conversationFileExists {
        //            try self.environment.fileManager.removeItem(at: self.conversationFileURL)
        //        }
        //
        //        if self.environment.fileManager.fileExists(atPath: self.messagesFileURL.path) {
        //            try self.environment.fileManager.removeItem(at: self.messagesFileURL)
        //        }
    }

    private var metadataURL: URL {
        return self.context.containerURL.appendingPathComponent("conversation-v1.meta")
    }

    private func conversationFileURL(for record: ConversationRoster.Record) -> URL {
        return self.context.containerURL.appendingPathComponent(record.path).appendingPathComponent("conversation-v1.archive")
    }

    private func messagesFileURL(for record: ConversationRoster.Record) -> URL {
        return self.context.containerURL.appendingPathComponent(record.path).appendingPathComponent("messages-v1.archive")
    }
}

extension EngagementMetrics {
    fileprivate init(legacyMetrics: [String: LegacyCount]) {
        self.metrics = legacyMetrics.mapValues {
            EngagementMetric(totalCount: $0.totalCount, versionCount: $0.versionCount, buildCount: $0.buildCount, lastInvoked: $0.lastInvoked)
        }
    }
}
