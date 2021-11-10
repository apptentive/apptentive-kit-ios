//
//  Message.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents an individual message within a list of messages.
public struct Message: Codable {
    /// The custom data associated with the message.
    var customData: CustomData
    /// The message id.
    let id: String?
    /// Indicates if the message is being received from the dashboard.
    let sentByLocalUser: Bool
    /// Indicates whether the message is a Context Message (shown after a "Don't Love" response triggered Message Center).
    var isAutomated: Bool
    /// Indicates whether the message shows in the message list to the consumer.
    var isHidden: Bool
    /// The set of media attachments associated with the message.
    var attachments: [Attachment]
    /// The sender information associated with the message.
    var sender: Sender?
    /// The body text of the message.
    var body: String?
    /// When when the message was created.
    var sentDate: Date

    internal init(
        body: String? = nil, attachments: [Message.Attachment] = [], isHidden: Bool = false, customData: CustomData = CustomData(), id: String? = nil, sentByLocalUser: Bool = true, isAutomated: Bool = false, sender: Message.Sender? = nil,
        sentDate: Date = Date()
    ) {
        self.customData = customData
        self.id = id
        self.sentByLocalUser = sentByLocalUser
        self.isAutomated = isAutomated
        self.isHidden = isHidden
        self.attachments = attachments
        self.sender = sender
        self.body = body
        self.sentDate = sentDate
    }

    // swift-format-ignore
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.customData = try container.decodeIfPresent(CustomData.self, forKey: .customData) ?? CustomData()
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
        self.sentByLocalUser = try container.decodeIfPresent(Bool.self, forKey: .sentByLocalUser) ?? false
        self.isAutomated = try container.decodeIfPresent(Bool.self, forKey: .isAutomated) ?? false
        self.isHidden = try container.decodeIfPresent(Bool.self, forKey: .isAutomated) ?? false
        self.body = try container.decodeIfPresent(String.self, forKey: .body)
        self.attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments) ?? []
        self.sender = try container.decodeIfPresent(Sender.self, forKey: .sender)
        self.sentDate = try container.decodeIfPresent(Date.self, forKey: .sentDate) ?? Date()
    }

    enum CodingKeys: String, CodingKey {
        case customData = "custom_data"
        case id
        case sentByLocalUser = "inbound"
        case isAutomated = "automated"
        case isHidden = "hidden"
        case attachments, sender, body
        case sentDate = "created_at"
    }

    /// Describes information associated with the sender of the message.
    struct Sender: Codable, Equatable {
        /// The id associated with the sender.
        let id: String
        /// The sender's name.
        var name: String?
        /// The profile photo of the sender if available.
        var profilePhotoURL: URL?

        enum CodingKeys: String, CodingKey {
            case id, name
            case profilePhotoURL = "profile_photo"
        }
    }

    /// Describes the media attachment assoiciated with each message.
    struct Attachment: Codable, Equatable {
        /// The specific media type.
        let mediaType: String
        /// The filename of the media type.
        let filename: String
        /// The URL for the media type.
        let url: URL?
        /// The data for the attachment.
        let data: Data?
    }
}
