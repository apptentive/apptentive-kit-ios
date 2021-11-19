//
//  Loader.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol Loader {
    init(containerURL: URL, environment: GlobalEnvironment)

    var conversationFileExists: Bool { get }

    func loadConversation() throws -> Conversation
    func loadPayloads() throws -> [Payload]
    func loadMessages() throws -> MessageList?

    func cleanUp() throws
}

enum LoaderError: Error {
    case cantRemoveCurrentFiles
    case noActiveAnonymousConversation
    case brokenVersion
}
