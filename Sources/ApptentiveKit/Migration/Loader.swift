//
//  Loader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol Loader: Sendable {
    init(context: LoaderContext)

    var rosterFileExists: Bool { get }
    func conversationFileExists(for record: ConversationRoster.Record) -> Bool

    func loadRoster(with tokenStore: SecureTokenStoring) throws -> ConversationRoster
    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation
    func loadPayloads() throws -> [Payload]
    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList?

    func cleanUpRoster() throws
    func cleanUp(for record: ConversationRoster.Record) throws
}

struct LoaderContext: @unchecked Sendable {
    let containerURL: URL
    let cacheURL: URL
    let appCredentials: Apptentive.AppCredentials
    let dataProvider: ConversationDataProviding
    let fileManager: FileManager
}

enum LoaderError: Swift.Error, LocalizedError {
    case cantRemoveCurrentFiles
    case noActiveAnonymousConversation
    case brokenVersion
    case unreadableLegacyMetadata
    case mismatchedAppCredentials
}
