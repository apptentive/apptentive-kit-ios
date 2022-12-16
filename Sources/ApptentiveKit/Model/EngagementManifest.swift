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
}

/// An object that represents the response to a request to the `interactions` endpoint of the Apptentive API.
public struct EngagementManifest: Expiring, Decodable {

    /// An array of `Interaction` objects.
    let interactions: [Interaction]

    /// A dictionary whose keys are code points (see `Event`) and whose values are `Invocation` objects.
    let targets: [String: [Invocation]]

    /// The date after which the engagement manifest should be considered stale.
    var expiry: Date?

    /// A structure combines an interaction identifier with criteria.
    public struct Invocation: Decodable {
        /// The ID of the interaction that should be presented if the criteria evaluate to true.
        let interactionID: String
        let criteria: Criteria

        private enum CodingKeys: String, CodingKey {
            case interactionID = "interaction_id"
            case criteria
        }
    }
}
