//
//  MessagesResponse.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/5/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

struct MessagesResponse: Codable {
    let messages: [Message]
    let endsWith: String
    let hasMore: Bool

    struct Message: Codable {
        let id: String
        let nonce: String
        let sentByLocalUser: Bool
        let body: String?
        let attachments: [Attachment]
        let sender: Sender?
        let isHidden: Bool?
        let isAutomated: Bool?
        let sentDate: Date

        struct Attachment: Codable {
            let contentType: String
            let filename: String
            let url: URL
            let size: Int

            enum CodingKeys: String, CodingKey {
                case contentType = "content_type"
                case filename = "original_name"
                case url, size
            }
        }

        struct Sender: Codable {
            let name: String?
            let profilePhoto: URL

            enum CodingKeys: String, CodingKey {
                case name
                case profilePhoto = "profile_photo"
            }
        }

        enum CodingKeys: String, CodingKey {
            case id, nonce
            case sentByLocalUser = "inbound"
            case body, attachments, sender
            case isHidden = "hidden"
            case isAutomated = "automated"
            case sentDate = "created_at"
        }
    }

    enum CodingKeys: String, CodingKey {
        case messages
        case endsWith = "ends_with"
        case hasMore = "has_more"
    }
}
