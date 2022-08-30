//
//  Conversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias ConversationEnvironment = DeviceEnvironment & AppEnvironment

/// Describes an object that can contain the information needed to connect to the Apptentive API.
protocol APICredentialsProviding {

    /// The key and signature to use when communicating with the Apptentive API.
    var appCredentials: Apptentive.AppCredentials? { get }

    /// The token and conversation ID used when communicating with the Apptentive API.
    var conversationCredentials: Conversation.ConversationCredentials? { get }

    var acceptLanguage: String? { get }
}

/// A object describing the state of the SDK, used for targeting and overall state management.
struct Conversation: Equatable, Codable, APICredentialsProviding {

    /// The key and signature to use when communicating with the Apptentive API.
    var appCredentials: Apptentive.AppCredentials?

    /// The token and conversation ID used when communicating with the Apptentive API.
    var conversationCredentials: ConversationCredentials?

    /// An object encapsulating the token and ID of a conversation.
    struct ConversationCredentials: Equatable, Codable {
        let token: String
        let id: String
    }

    /// The app release corresponding to the conversation.
    var appRelease: AppRelease

    /// The person corresponding to the conversation.
    var person: Person

    /// The device corresponding to the conversation.
    var device: Device

    /// The metrics for engaged code points.
    var codePoints: EngagementMetrics

    /// The metrics for presented interactions.
    var interactions: EngagementMetrics

    /// The values used for determining whether a conversation is part of a random sample.
    var random: Random

    /// Initializes a conversation with the specified environment.
    /// - Parameter environment: The environment used to create the initial app release and device values.
    init(environment: ConversationEnvironment) {
        self.appRelease = AppRelease(environment: environment)
        self.person = Person()
        self.device = Device(environment: environment)
        self.codePoints = EngagementMetrics()
        self.interactions = EngagementMetrics()
        self.random = Random()
    }

    /// Merges the conversation with a newer conversation.
    /// - Parameter newer: The newer conversation.
    /// - Throws: An error if the app- or conversation credentials are mismatched.
    mutating func merge(with newer: Conversation) throws {
        guard self.appCredentials == nil || newer.appCredentials == nil || self.appCredentials == newer.appCredentials else {
            apptentiveCriticalError("Apptentive Key and Signature have changed from their previous values, which is not supported.")
            throw ApptentiveError.internalInconsistency
        }

        guard self.conversationCredentials == nil || newer.conversationCredentials == nil || self.conversationCredentials == newer.conversationCredentials else {
            apptentiveCriticalError("Both new and existing conversations have tokens, but they do not match.")
            throw ApptentiveError.internalInconsistency
        }

        if appRelease.version ?? 0 < newer.appRelease.version ?? 0 {
            self.codePoints.resetVersion()
            self.interactions.resetVersion()
        }

        if appRelease.build ?? 0 < newer.appRelease.build ?? 0 {
            self.codePoints.resetBuild()
            self.interactions.resetBuild()
        }

        self.appRelease.merge(with: newer.appRelease)
        self.person.merge(with: newer.person)
        self.device.merge(with: newer.device)
        self.codePoints.merge(with: newer.codePoints)
        self.interactions.merge(with: newer.interactions)
        self.random.merge(with: newer.random)
    }

    /// Creates a new conversation merged with the specified newer conversation.
    /// - Parameter newer: The newer conversation to merge with the receiver.
    /// - Throws: An error if the app- or conversation credentials are mismatched.
    /// - Returns: The merged conversation.
    func merged(with newer: Conversation) throws -> Conversation {
        var copy = self

        try copy.merge(with: newer)

        return copy
    }

    // MARK: APICredentialsProviding

    var acceptLanguage: String? {
        return self.device.localeLanguageCode
    }
}
