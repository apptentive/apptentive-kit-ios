//
//  EngagementManifest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol Expiring {
    var expiry: Date? { get set }
}

struct EngagementManifest: Expiring, Decodable {
    let interactions: [Interaction]
    let targets: [String: [Invocation]]
    var expiry: Date?

    struct Invocation: Decodable {
        let interactionID: String

        private enum CodingKeys: String, CodingKey {
            case interactionID = "interaction_id"
        }
    }
}
