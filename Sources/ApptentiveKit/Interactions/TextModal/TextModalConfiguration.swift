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
    let name: String?
    let body: String?
    let actions: [Action]
    let image: Image?

    struct Action: Decodable {
        let id: String
        let label: String
        let actionType: ActionType
        let invocations: [EngagementManifest.Invocation]?

        enum ActionType: String, Decodable {
            case dismiss
            case interaction
        }

        enum CodingKeys: String, CodingKey {
            case id
            case label
            case actionType = "action"
            case invocations = "invokes"
        }
    }

    struct Image: Decodable {
        let url: URL
        let layout: String
        let altText: String

        enum CodingKeys: String, CodingKey {
            case url
            case layout
            case altText = "alt_text"
        }
    }

    enum CodingKeys: String, CodingKey {
        case title
        case name
        case body
        case actions
        case image
    }
}
