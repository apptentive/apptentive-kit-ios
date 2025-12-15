//
//  EngagementManifest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes an object that should be considered stale after a particular date.
protocol Expiring {
    /// The date after which the object should be considered stale.
    var expiry: Date? { get set }

    /// The date that this version of the object was downloaded.
    var downloadTime: Date? { get set }
}

/// An object that represents the response to a request to the `interactions` endpoint of the Apptentive API.
struct EngagementManifest: Expiring, Decodable {

    /// An array of `Interaction` objects.
    var interactions: [Interaction]

    /// A dictionary whose keys are code points (see `Event`) and whose values are `Invocation` objects.
    var targets: [String: [Invocation]]

    /// A list of resources to pre-fetch so that interactions can use them without a loading delay.
    var prefetch: [URL]?

    /// The server-side ID of the application.
    var applicationID: String

    /// The date after which the engagement manifest should be considered stale.
    var expiry: Date?

    /// The date when the engagement manifest was downloaded.
    var downloadTime: Date?

    /// Marker for placeholder manifest.
    var isPlaceholder: Bool = false

    /// A structure combines an interaction identifier with criteria.
    struct Invocation: Decodable {
        /// The ID of the interaction that should be presented if the criteria evaluate to true.
        let interactionID: String
        let criteria: Criteria

        private enum CodingKeys: String, CodingKey {
            case interactionID = "interaction_id"
            case criteria
        }
    }

    private enum CodingKeys: String, CodingKey {
        case interactions, targets, prefetch
        case applicationID = "application_id"
    }
}
