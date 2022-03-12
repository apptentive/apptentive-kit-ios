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
    var draftMessage: Message
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
        /// Whether the message was sent by an automatic process (for example, a context message).
        var isAutomated: Bool
        /// Whether the message should be hidden in the Message Center UI.
        var isHidden: Bool
        /// Indicates if the status of the message.
        var status: Status

        init(nonce: String, body: String? = nil, attachments: [Attachment] = [], sender: MessageList.Message.Sender? = nil, sentDate: Date = Date(), isAutomated: Bool = false, isHidden: Bool = false, status: MessageList.Message.Status = .draft) {
            self.nonce = nonce
            self.body = body
            self.attachments = attachments
            self.sender = sender
            self.sentDate = sentDate
            self.isAutomated = isAutomated
            self.isHidden = isHidden
            self.status = status
        }

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
            /// Where the attachment is stored.
            var storage: Storage
            /// The PNG data of a thumbnail, if available.
            var thumbnailData: Data?
            /// The progress of the download task.
            var downloadProgress: Float

            init(contentType: String, filename: String, storage: Storage, thumbnailData: Data? = nil) {
                self.contentType = contentType
                self.filename = filename
                self.storage = storage
                self.thumbnailData = thumbnailData
                self.downloadProgress = 0
            }

            enum Storage: Codable, Equatable {
                case remote(URL, size: Int)
                case cached(path: String)  // Path relative to container directory in Library/Caches.
                case saved(path: String)  // Path relative to container directory in Library/Application Support.
                case inMemory(Data)
            }
        }

        enum Status: Codable, Equatable {
            case draft
            case queued
            case sending
            case sent
            case unread
            case read
            case failed
        }
    }
}
