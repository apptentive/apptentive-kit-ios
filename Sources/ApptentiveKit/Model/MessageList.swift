//
//  MessageList.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Data object for storing/persisting ``MessageManager`` data.
struct MessageList: Codable, Equatable {
    var messages: [Message]
    var lastDownloadedMessageID: String?
    var additionalDownloadableMessagesExist: Bool = false
    var draftMessage: OutgoingMessage?
    var lastFetchDate: Date?

    /// Represents an individual message within a list of messages.
    struct Message: Codable, Equatable {
        /// The nonce assigned to the message.
        var nonce: String
        /// The body text of the message.
        var body: String?
        /// The set of media attachments associated with the message.
        var attachments: [Attachment]
        /// The sender information associated with the message.
        var sender: Sender?
        /// When when the message was created.
        var sentDate: Date
        /// Indicates if the status of the message.
        var status: Status

        /// Describes information associated with the sender of the message.
        struct Sender: Codable, Equatable {
            /// The sender's name.
            var name: String?
            /// The profile photo of the sender if available.
            var profilePhoto: URL?
        }

        /// Describes the media attachment assoiciated with each message.
        struct Attachment: Codable, Equatable {
            /// The content type of the attachment.
            let contentType: String
            /// The filename of the attachment.
            let filename: String
            /// The remote URL for downloading the attachment data.
            let url: URL?
            /// The size of attachment data in bytes.
            let size: Int?
        }

        enum Status: Codable, Equatable {
            case queued
            case sending
            case sent
            case unread
            case read
            case automated
            case hidden
            case failed
            case unknown
        }
    }
}
