//
//  Loader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol Loader {
    init(containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment)

    var rosterFileExists: Bool { get }
    func conversationFileExists(for record: ConversationRoster.Record) -> Bool

    func loadRoster() throws -> ConversationRoster
    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation
    func loadPayloads() throws -> [Payload]
    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList?

    func cleanUpRoster() throws
    func cleanUp(for record: ConversationRoster.Record) throws
}

enum LoaderError: Swift.Error, LocalizedError {
    case cantRemoveCurrentFiles
    case noActiveAnonymousConversation
    case brokenVersion
    case unreadableLegacyMetadata
    case mismatchedAppCredentials
}
