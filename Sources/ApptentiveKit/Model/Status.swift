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
    let sdkEnabled: Bool?

    /// Whether customer-engaged events should be reported to the API.
    let metricsEnabled: Bool

    /// The date/time after which this object should be considered stale.
    var expiry: Date? = .distantPast

    /// The date/time at which this object was downloaded/cached.
    var downloadTime: Date? = .distantPast

    var perSessionInteractionLimit: Int = 1

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
        case sdkEnabled = "sdk_enabled"
        case metricsEnabled = "metrics_enabled"
        case perSessionInteractionLimit = "per_session_interaction_limit"

        // The server never sends these — `ApptentiveAPI.transformResponse` always overwrites them
        // from the response's `Cache-Control` header right after decoding — but they do need to be
        // in `CodingKeys` so `Backend`'s local plist persistence of `Status` (so a cold launch can
        // tell whether the cached status has actually expired) round-trips them at all. Without
        // this, both silently fall back to their declared defaults on every decode, including from
        // the saved plist, making every loaded status look permanently expired.
        case expiry
        case downloadTime
    }
}
