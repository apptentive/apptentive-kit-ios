//
//  MessageList.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the top level object for messages.
struct MessageList: Codable {
    /// The array of messages between the consumer and the dashboard.
    let messages: [Message]
    /// The identifier associated with the last message.
    let endsWith: String?
    /// Indicates whether there are more messages.
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case messages
        case endsWith = "ends_with"
        case hasMore = "has_more"
    }

    init(messages: [Message] = [], endsWith: String? = nil, hasMore: Bool = false) {
        self.messages = messages
        self.endsWith = endsWith
        self.hasMore = hasMore
    }

    /// Represents an individual message within a list of messages.
    struct Message: Codable {
        /// The message id.
        let id: String?
        /// The body text of the message.
        var body: String?
        /// The set of media attachments associated with the message.
        var attachments: [Attachment]
        /// The sender information associated with the message.
        var sender: Sender?
        /// When when the message was created.
        var sentDate: Date
        /// Indicates if the message is being received from the dashboard.
        let sentByLocalUser: Bool
        /// Indicates whether the message is a Context Message (shown after a "Don't Love" response triggered Message Center).
        var isAutomated: Bool
        /// Indicates whether the message shows in the message list to the consumer.
        var isHidden: Bool

        init(id: String?, body: String? = nil, attachments: [MessageList.Message.Attachment], sender: MessageList.Message.Sender? = nil, sentDate: Date, sentByLocalUser: Bool, isAutomated: Bool, isHidden: Bool) {
            self.id = id
            self.body = body
            self.attachments = attachments
            self.sender = sender
            self.sentDate = sentDate
            self.sentByLocalUser = sentByLocalUser
            self.isAutomated = isAutomated
            self.isHidden = isHidden
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

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
            /// The content type of the attachment.
            let contentType: String
            /// The filename of the attachment.
            let filename: String
            /// The URL for downloading the attachment data.
            let url: URL?
            /// The size of attachment data in bytes.
            let size: Int?

            enum CodingKeys: String, CodingKey {
                case contentType = "content_type"
                case filename = "original_name"
                case size
                case url
            }
        }
    }
}
