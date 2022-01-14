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
