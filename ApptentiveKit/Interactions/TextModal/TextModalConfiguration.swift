//
//  TextModalConfiguration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct TextModalConfiguration: Decodable {
    let title: String?
    let body: String?
    let actions: [Action]

    struct Action: Decodable {
        let id: String
        let label: String
        let actionType: ActionType
        let invocations: [EngagementManifest.Invocation]?
        let event: String?

        enum ActionType: String, Decodable {
            case dismiss
            case interaction
        }

        enum CodingKeys: String, CodingKey {
            case id
            case label
            case actionType = "action"
            case invocations = "invokes"
            case event
        }
    }
}
