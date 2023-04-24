//
//  ALoader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/8/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ALoader: Loader {
    static let conversationFilename = "Conversation.A"
    static let payloadsFilename = "PayloadQueue.A"
    static let messagesFilename = "MessageList.A"
    static let fileExtension = "plist"

    /// The URL from which to load the files.
    ///
    /// Note that when loading common files, this is set to the top-level container directory.
    /// When loading files for a particular record, it is set to the record's subdirectory.
    let containerURL: URL

    let appCredentials: Apptentive.AppCredentials
    let environment: GlobalEnvironment
    let decoder = PropertyListDecoder()
    let newConversationPath: String

    init(containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment) {
        self.containerURL = containerURL
        self.appCredentials = appCredentials
        self.environment = environment
        self.newConversationPath = UUID().uuidString
    }

    var rosterFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.commonConversationFileURL.path)
    }

    func conversationFileExists(for record: ConversationRoster.Record) -> Bool {
        return self.environment.fileManager.fileExists(atPath: self.conversationFileURL.path)
    }

    func loadRoster() throws -> ConversationRoster {
        let data = try Data(contentsOf: self.commonConversationFileURL)
        let aConversation = try self.decoder.decode(AConversation.self, from: data)

        guard self.appCredentials == aConversation.appCredentials else {
            ApptentiveLogger.default.warning("App credentials for the existing conversation do not match. Creating a new conversation.")
            throw LoaderError.mismatchedAppCredentials
        }

        let state: ConversationRoster.Record.State
        if let aConversationCredentials = aConversation.conversationCredentials {
            state = .anonymous(credentials: .init(id: aConversationCredentials.id, token: aConversationCredentials.token))
        } else {
            state = .anonymousPending
        }

        return ConversationRoster(active: .init(state: state, path: self.newConversationPath), loggedOut: [])
    }

    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation {
        let data = try Data(contentsOf: self.conversationFileURL)
        let aConversation = try self.decoder.decode(AConversation.self, from: data)

        var conversation = Conversation(environment: self.environment)
        conversation.appRelease = aConversation.appRelease
        conversation.person = aConversation.person
        conversation.device = aConversation.device.currentDevice(with: self.environment)
        conversation.codePoints = aConversation.codePoints
        conversation.interactions = aConversation.interactions
        conversation.random = aConversation.random

        // Create directory that migrated conversation will be saved to.
        try self.environment.fileManager.createDirectory(atPath: self.containerURL.appendingPathComponent(record.path).path, withIntermediateDirectories: true)

        return conversation
    }

    func loadPayloads() throws -> [Payload] {
        if self.payloadsFileExists {
            let data = try Data(contentsOf: self.payloadsFileURL)
            let aPayloads = try self.decoder.decode([APayload].self, from: data)
            let jsonEncoder = JSONEncoder.apptentive

            // Rebase attachment URLs (this mostly comes up in testing)
            return try aPayloads.map { aPayload in
                let context = Payload.Context(tag: self.newConversationPath, credentials: .placeholder, sessionID: aPayload.jsonObject.sessionID, encoder: jsonEncoder, encryptionContext: nil)

                let movedAttachments = aPayload.attachments.map { (attachment) -> Payload.Attachment in
                    switch attachment.contents {
                    case .file(let url):
                        let movedURL = self.containerURL.appendingPathComponent(url.lastPathComponent)
                        return Payload.Attachment(parameterName: attachment.parameterName, contentType: attachment.contentType, filename: attachment.filename, contents: .file(movedURL))

                    case .data(_):
                        return attachment
                    }
                }

                return try Payload(context: context, specializedJSONObject: aPayload.jsonObject.specializedJSONObject, path: aPayload.path, method: aPayload.method, attachments: movedAttachments)
            }
        } else {
            return []
        }
    }

    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList? {
        if self.messagesFileExists {
            let data = try Data(contentsOf: self.messagesFileURL)
            return try self.decoder.decode(MessageList.self, from: data)
        } else {
            return nil
        }
    }

    func cleanUpRoster() throws {
        // No roster file to clean up.

        if self.payloadsFileExists {
            try self.environment.fileManager.removeItem(at: self.payloadsFileURL)
        }
    }

    func cleanUp(for record: ConversationRoster.Record) throws {
        if self.conversationFileExists(for: record) {
            try self.environment.fileManager.removeItem(at: self.conversationFileURL)
        }

        if self.messagesFileExists {
            try self.environment.fileManager.removeItem(at: self.messagesFileURL)
        }
    }

    private var commonConversationFileURL: URL {
        // We don't have a roster in this version, so check for a conversation at the top level.
        return self.containerURL.appendingPathComponent(Self.conversationFilename).appendingPathExtension(Self.fileExtension)
    }

    private var conversationFileURL: URL {
        // Have to move up one level because A conversations are stored in the root of the container directory, and `containerURL` has new path segment already in it.
        return self.containerURL.appendingPathComponent(Self.conversationFilename).appendingPathExtension(Self.fileExtension)
    }

    private var payloadsFileURL: URL {
        return self.containerURL.appendingPathComponent(Self.payloadsFilename).appendingPathExtension(Self.fileExtension)
    }

    private var messagesFileURL: URL {
        // Have to move up one level because A conversations are stored in the root of the container directory, and `containerURL` has new path segment already in it.
        return self.containerURL.appendingPathComponent(Self.messagesFilename).appendingPathExtension(Self.fileExtension)
    }

    private var payloadsFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.payloadsFileURL.path)
    }

    private var messagesFileExists: Bool {
        return self.environment.fileManager.fileExists(atPath: self.messagesFileURL.path)
    }
}
