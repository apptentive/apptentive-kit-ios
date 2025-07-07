//
//  FreshLoader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/23/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

struct FreshLoader: Loader {
    let context: LoaderContext
    let newConversationPath: String

    init(context: LoaderContext) {
        self.context = context
        self.newConversationPath = UUID().uuidString
    }

    var rosterFileExists: Bool {
        return true
    }

    func conversationFileExists(for record: ConversationRoster.Record) -> Bool {
        return true
    }

    func loadRoster() throws -> ConversationRoster {
        try self.createDirectoryIfNeeded(containerURL: self.context.containerURL, fileManager: self.context.fileManager)
        try self.createDirectoryIfNeeded(containerURL: self.context.cacheURL, fileManager: self.context.fileManager)

        return ConversationRoster(active: .init(state: .anonymousPending, path: newConversationPath), loggedOut: [])
    }

    func loadConversation(for record: ConversationRoster.Record) throws -> Conversation {
        try self.createDirectoryIfNeeded(containerURL: self.context.containerURL.appendingPathComponent(record.path), fileManager: self.context.fileManager)

        return Conversation(dataProvider: self.context.dataProvider)
    }

    func loadPayloads() throws -> [Payload] {
        return []
    }

    func loadMessages(for record: ConversationRoster.Record) throws -> MessageList? {
        return nil
    }

    func cleanUpRoster() throws {}

    func cleanUp(for record: ConversationRoster.Record) throws {}

    /// Creates a container directory if does not already exist.
    /// - Parameters:
    ///   - containerURL: The URL at which the directory should reside.
    ///   - fileManager: The `FileManager` object used to create the directory.
    /// - Throws: An error if the directory can't be created, or if an existing file is in the way of the directory.
    private func createDirectoryIfNeeded(containerURL: URL, fileManager: FileManager) throws {
        var isDirectory: ObjCBool = false

        if !fileManager.fileExists(atPath: containerURL.path, isDirectory: &isDirectory) {
            Logger.default.debug("Creating directory for Apptentive SDK data at \(containerURL).")

            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        } else if !isDirectory.boolValue {
            throw ApptentiveError.fileExistsAtContainerDirectoryPath
        }
    }
}
