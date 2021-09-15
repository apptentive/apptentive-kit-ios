//
//  Message.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct MessageList: Codable {
    let messages: [Message]
    let endsWith: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case messages
        case endsWith = "ends_with"
        case hasMore = "has_more"
    }
}

struct Message: Codable {
    let customData: String?
    let id: String
    let inbound: Bool
    let attachments: [String]
    let createdAt: Double
    let sender: Sender
    let body: String

    enum CodingKeys: String, CodingKey {
        case customData = "custom_data"
        case id, inbound, attachments
        case createdAt = "created_at"
        case sender, body
    }

    struct Sender: Codable {
        let id: String
        let name: String?
        let profilePhoto: String

        enum CodingKeys: String, CodingKey {
            case id, name
            case profilePhoto = "profile_photo"
        }
    }
}
