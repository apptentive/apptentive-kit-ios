//
//  Status.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/16/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object representing the data downloaded from the status endpoint.
struct Status: Codable, Expiring {
    /// The last time that the engagement manifest for this app was updated by the customer.
    let lastUpdate: Date

    /// An object describing the non-interaction-specific Message Center properties.
    let messageCenter: MessageCenter

    /// The date/time until which the SDK should stop presenting interactions and/or sending payloads to the API.
    let hibernateUntil: Date?

    /// Whether customer-engaged events should be reported to the API.
    let metricsEnabled: Bool

    /// The date/time after which this object should be considered stale.
    var expiry: Date? = .distantPast

    /// The date/time at which this object was downloaded/cached.
    var downloadTime: Date? = .distantPast

    /// An object describing the non-interaction-specific Message Center properties.
    struct MessageCenter: Codable {
        /// The rate at which to poll the messages endpoint when Message Center is presented.
        let foregroundPollingInterval: TimeInterval

        /// The rate at which to pool the messages endpoint when Message Center is not presented.
        let backgroundPollingInterval: TimeInterval

        enum CodingKeys: String, CodingKey {
            case foregroundPollingInterval = "fg_poll"
            case backgroundPollingInterval = "bg_poll"
        }
    }

    enum CodingKeys: String, CodingKey {
        case lastUpdate = "last_update"
        case messageCenter = "message_center"
        case hibernateUntil = "hibernate_until"
        case metricsEnabled = "metrics_enabled"
    }
}
