//
//  LegacyLoader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct LegacyLoader: Loader {
    let containerURL: URL
    let environment: GlobalEnvironment

    init(containerURL: URL, environment: GlobalEnvironment) {
        self.containerURL = containerURL
        self.environment = environment
    }

    var conversationFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.metadataURL.path)
    }

    func loadConversation() throws -> Conversation {
        let data = try Data(contentsOf: self.metadataURL)
        let legacyConversationMetadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversationMetadata.self, from: data)

        // Look for an anonymous conversation's metadata item.
        guard let activeConversationMetadataItem = legacyConversationMetadata?.items.first(where: { $0.state == .anonymous }),
            let token = activeConversationMetadataItem.jwt,
            let id = activeConversationMetadataItem.identifier,
            let directory = activeConversationMetadataItem.directoryName
        else {
            throw LoaderError.noActiveAnonymousConversation
        }

        // Create a blank conversation and add the legacy credentials.
        var conversation = Conversation(environment: self.environment)
        conversation.conversationCredentials = Conversation.ConversationCredentials(token: token, id: id)

        // Try to load the corresponding conversation.
        let conversationFileURL = self.containerURL.appendingPathComponent("\(directory)/conversation-v1.archive")
        let conversationData = try Data(contentsOf: conversationFileURL)
        let legacyConversation = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversation.self, from: conversationData)

        // Copy over iteraction metrics if possible.
        if let legacyInteractions = legacyConversation?.engagement?.interactions {
            conversation.interactions = EngagementMetrics(legacyMetrics: legacyInteractions)
        } else {
            throw ApptentiveError.internalInconsistency
        }

        // Copy over code point metrics if possible.
        if let legacyCodePoints = legacyConversation?.engagement?.codePoints {
            conversation.codePoints = EngagementMetrics(legacyMetrics: legacyCodePoints)
        } else {
            throw ApptentiveError.internalInconsistency
        }

        return conversation
    }

    func loadPayloads() throws -> [Payload] {
        // Not trying to migrate these as it would involve standing up a whole Core Data stack.
        return []
    }

    func loadMessages() throws -> MessageList? {
        // These are also complicated to migrate and can just be re-downloaded.
        return nil
    }

    func cleanUp() throws {
        // Until we're out of beta, keep the legacy conversation around.

        // let data = try Data(contentsOf: self.metadataURL)
        // let legacyConversationMetadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversationMetadata.self, from: data)
        //
        // // Look for an anonymous conversation's metadata item.
        // try legacyConversationMetadata?.items.compactMap { $0.directoryName }.forEach { directoryName in
        //     let conversationDirectoryURL = self.containerURL.appendingPathComponent(directoryName, isDirectory: true)
        //     try self.environment.fileManager.removeItem(at: conversationDirectoryURL)
        // }
        //
        // try self.environment.fileManager.removeItem(at: self.metadataURL)
    }

    private var metadataURL: URL {
        return self.containerURL.appendingPathComponent("conversation-v1.meta")
    }
}

extension EngagementMetrics {
    fileprivate init(legacyMetrics: [String: LegacyCount]) {
        self.metrics = legacyMetrics.mapValues {
            EngagementMetric(totalCount: $0.totalCount, versionCount: $0.versionCount, buildCount: $0.buildCount, lastInvoked: $0.lastInvoked)
        }
    }
}
