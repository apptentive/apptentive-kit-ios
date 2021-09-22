//
//  Message.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Message: Codable {
    var customData: CustomData
    let id: String?
    let isInbound: Bool
    var isAutomated: Bool
    var isHidden: Bool
    var attachments: [Attachment]
    var sender: Sender?
    var body: String?

    internal init(body: String? = nil, attachments: [Message.Attachment] = [], isHidden: Bool = false, customData: CustomData = CustomData(), id: String? = nil, isInbound: Bool = false, isAutomated: Bool = false, sender: Message.Sender? = nil) {
        self.customData = customData
        self.id = id
        self.isInbound = isInbound
        self.isAutomated = isAutomated
        self.isHidden = isHidden
        self.attachments = attachments
        self.sender = sender
        self.body = body
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.customData = try container.decodeIfPresent(CustomData.self, forKey: .customData) ?? CustomData()
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.isInbound = try container.decodeIfPresent(Bool.self, forKey: .isInbound) ?? false
        self.isAutomated = try container.decodeIfPresent(Bool.self, forKey: .isAutomated) ?? false
        self.isHidden = try container.decodeIfPresent(Bool.self, forKey: .isAutomated) ?? false
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
        self.attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments) ?? []
        self.sender = try container.decodeIfPresent(Sender.self, forKey: .sender)
    }

    enum CodingKeys: String, CodingKey {
        case customData = "custom_data"
        case id
        case isInbound = "inbound"
        case isAutomated = "automated"
        case isHidden = "hidden"
        case attachments, sender, body
    }

    struct Sender: Codable, Equatable {
        let id: String
        var name: String?
        var profilePhotoURL: URL?

        enum CodingKeys: String, CodingKey {
            case id, name
            case profilePhotoURL = "profile_photo"
        }
    }

    struct Attachment: Codable {
        let mediaType: String
        let filename: String
        let data: Data?
        let url: URL?
    }
}
