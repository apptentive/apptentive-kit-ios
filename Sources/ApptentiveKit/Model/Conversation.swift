//
//  Conversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// A object describing the state of the SDK, used for targeting and overall state management.
struct Conversation: Equatable, Codable {

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

    /// The time after which the engagement manifest should be considered stale.
    var interactionsInvalidation: Date?

    /// The version of the app release that was last confirmed as enqueued for sending to the API.
    ///
    /// Persisted alongside the rest of the conversation (rather than kept in memory only) so that, across
    /// an app launch, syncing can tell what's actually been sent from what's merely been saved locally.
    /// Optional (rather than defaulted) so that decoding a conversation predating this property yields `nil`
    /// (meaning "never synced") instead of throwing.
    var lastSyncedAppRelease: AppRelease?

    /// The version of the person that was last confirmed as enqueued for sending to the API.
    ///
    /// See `lastSyncedAppRelease` for why this is optional rather than defaulted.
    var lastSyncedPerson: Person?

    /// The version of the device that was last confirmed as enqueued for sending to the API.
    ///
    /// See `lastSyncedAppRelease` for why this is optional rather than defaulted.
    var lastSyncedDevice: Device?

    /// Initializes a conversation with the specified data provider.
    /// - Parameter dataProvider: The data provider used to create the initial app release and device values.
    init(dataProvider: ConversationDataProviding) {
        self.appRelease = AppRelease(dataProvider: dataProvider)
        self.person = Person()
        self.device = Device(dataProvider: dataProvider)
        self.codePoints = EngagementMetrics()
        self.interactions = EngagementMetrics()
        self.random = Random()
    }

    /// Merges the conversation with a newer conversation.
    /// - Parameter newer: The newer conversation.
    /// - Throws: An error if the app- or conversation credentials are mismatched.
    mutating func merge(with newer: Conversation) throws {
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

        // `newer` is the in-memory placeholder conversation created before disk load finished, so it should
        // never actually have a later sync baseline than `self` (the disk-loaded conversation) in practice —
        // but prefer it if present, consistent with the last-write-wins strategy used above.
        self.lastSyncedAppRelease = newer.lastSyncedAppRelease ?? self.lastSyncedAppRelease
        self.lastSyncedPerson = newer.lastSyncedPerson ?? self.lastSyncedPerson
        self.lastSyncedDevice = newer.lastSyncedDevice ?? self.lastSyncedDevice
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
}
