//
//  LegacyConversationRepository.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/27/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

class LegacyConversationRepository: FileRepository<Conversation> {
    let environment: GlobalEnvironment

    init(containerURL: URL, filename: String, environment: GlobalEnvironment) {
        self.environment = environment

        super.init(containerURL: containerURL, filename: filename, fileManager: environment.fileManager)
    }

    override func load() throws -> Conversation {
        let data = try self.loadData()
        let legacyConversationMetadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LegacyConversationMetadata.self, from: data)

        // Look for an anonymous conversation's metadata item.
        guard let activeConversationMetadataItem = legacyConversationMetadata?.items.first(where: { $0.state == .anonymous }),
            let token = activeConversationMetadataItem.jwt,
            let id = activeConversationMetadataItem.identifier,
            let directory = activeConversationMetadataItem.directoryName
        else {
            throw ApptentiveMigrationError.noActiveAnonymousConversation
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
}

extension EngagementMetrics {
    init(legacyMetrics: [String: LegacyCount]) {
        self.metrics = legacyMetrics.mapValues {
            EngagementMetric(totalCount: $0.totalCount, versionCount: $0.versionCount, buildCount: $0.buildCount, lastInvoked: $0.lastInvoked)
        }
    }
}

enum ApptentiveMigrationError: Error {
    case noActiveAnonymousConversation
}
