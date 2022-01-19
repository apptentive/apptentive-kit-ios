//
//  MessageCenterViewModel+Message.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

extension MessageCenterViewModel {
    /// Represents a message in the Message Center UI.
    public struct Message {
        /// Indicates if the message is being received from the dashboard.
        public let sentByLocalUser: Bool

        /// Indicates whether the message is a Context Message (shown after a "Don't Love" response triggered Message Center).
        public let isAutomated: Bool

        /// Indicates whether the message shows in the message list to the consumer.
        public let isHidden: Bool

        /// The set of media attachments associated with the message.
        public let attachments: [Attachment]

        /// The sender information associated with the message.
        public let sender: Sender?

        /// The body text of the message.
        public let body: String?

        /// When when the message was created.
        public let sentDate: Date

        /// Whether the message was displayed to the user.
        public var wasRead: Bool

        /// The formatter for the sent date labels.
        public var sentDateFormatter: DateFormatter

        /// A human-readable string of the date that the message was sent.
        public var sentDateString: String {
            return self.sentDateFormatter.string(from: self.sentDate)
        }

        ///  The name of the sender, if any.
        public var senderName: String? {
            return self.sender?.name
        }

        /// Returns a URL pointing to the an image for the sender (if any).
        public var senderImageURL: URL? {
            return self.sender?.profilePhotoURL
        }

        /// Indicates if the message has attachments.
        public var messageIncludesAttachments: MessageAttachmentStatus {
            switch self.attachments.isEmpty {
            case true:
                return .noAttachments
            case false:
                return .hasAttachments
            }
        }

        /// Indicates if the message is outbound or inbound.
        public var messageState: MessageStatus {
            switch self.sentByLocalUser {
            case true:
                return .outbound
            case false:
                return .inbound
            }
        }

        init(sentByLocalUser: Bool, isAutomated: Bool, isHidden: Bool, attachments: [Attachment], sender: Sender?, body: String?, sentDate: Date, wasRead: Bool) {
            self.sentByLocalUser = sentByLocalUser
            self.isAutomated = isAutomated
            self.isHidden = isHidden
            self.attachments = attachments
            self.sender = sender
            self.body = body
            self.sentDate = sentDate
            self.wasRead = wasRead
            self.sentDateFormatter = DateFormatter()
            self.sentDateFormatter.dateStyle = .none
            self.sentDateFormatter.timeStyle = .short
        }

        /// Defines the status of the message whether it is an inbound message or outbound.
        public enum MessageStatus {
            /// The message is coming from the server.
            case inbound
            /// The message is being sent from the device.
            case outbound
        }

        /// Defines the status of the message attachments.
        public enum MessageAttachmentStatus {
            /// The message has no attachments.
            case noAttachments
            /// The message has attachments.
            case hasAttachments
        }

        /// The information associated with the sender of the message.
        public struct Sender: Equatable {
            /// The sender's name.
            var name: String?

            /// The profile photo of the sender if available.
            var profilePhotoURL: URL?
        }

        /// An attachment that can be associated with a message.
        public struct Attachment: Equatable {
            /// The specific media type.
            let mediaType: String

            /// The filename of the media type.
            let filename: String

            /// The URL for the attachment.
            let url: URL
        }
    }
}
