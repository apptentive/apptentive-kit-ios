//
//  TextModalConfiguration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct TextModalConfiguration: Decodable {
    let title: AttributedString?
    let name: String?
    let body: AttributedString?
    let actions: [Action]
    let image: Image?

    init(title: AttributedString? = nil, name: String? = nil, body: AttributedString? = nil, actions: [TextModalConfiguration.Action], image: TextModalConfiguration.Image? = nil) {
        self.title = title
        self.name = name
        self.body = body
        self.actions = actions
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.apptentiveDecodeHTMLIfPresent(forKey: .title)
        self.body = try container.apptentiveDecodeHTMLIfPresent(forKey: .body)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.actions = try container.decode([Action].self, forKey: .actions)
        self.image = try container.decodeIfPresent(Image.self, forKey: .image)
    }

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
