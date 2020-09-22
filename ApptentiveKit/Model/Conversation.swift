//
//  Conversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias ConversationEnvironment = DeviceEnvironment & AppEnvironment

struct Conversation: Codable {
    var appCredentials: Apptentive.AppCredentials?
    var conversationCredentials: ConversationCredentials?

    struct ConversationCredentials: Equatable, Codable {
        let token: String
        let id: String
    }

    var appRelease: AppRelease
    var person: Person
    var device: Device

    init(environment: ConversationEnvironment) {
        self.appRelease = AppRelease(environment: environment)
        self.person = Person()
        self.device = Device(environment: environment)
    }

    mutating func merge(with newer: Conversation) throws {
        guard self.appCredentials == nil || newer.appCredentials == nil || self.appCredentials == newer.appCredentials else {
            assertionFailure("Apptentive Key and Signature have changed from their previous values, which is not supported.")
            throw ApptentiveError.internalInconsistency
        }

        guard self.conversationCredentials == nil || newer.conversationCredentials == nil || self.conversationCredentials == newer.conversationCredentials else {
            assertionFailure("Both new and existing conversations have tokens, but they do not match.")
            throw ApptentiveError.internalInconsistency
        }

        self.appRelease.merge(with: newer.appRelease)
        self.person.merge(with: newer.person)
        self.device.merge(with: newer.device)
    }

    func merged(with newer: Conversation) throws -> Conversation {
        var copy = self

        try copy.merge(with: newer)

        return copy
    }
}
