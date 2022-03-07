//
//  MessageCenterViewModel+Message.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import QuickLook
import UIKit

extension MessageCenterViewModel {
    /// Represents a message in the Message Center UI.
    public class Message: Equatable {
        /// The nonce of the message.
        public let nonce: String

        /// Indicates if the message is outbound or inbound.
        public let direction: Direction

        /// Indicates whether the message is a Context Message (shown after a "Don't Love" response triggered Message Center).
        public let isAutomated: Bool

        /// The set of media attachments associated with the message.
        public let attachments: [Attachment]

        /// The sender information associated with the message.
        public let sender: Sender?

        /// The body text of the message.
        public let body: String?

        /// When when the message was created.
        public let sentDate: Date

        /// The accessibility label of the message for VoiceOver.
        public let accessibilityLabel: String?

        /// The accessibility hint of the message for VoiceOver.
        public let accessibilityHint: String?

        /// A textual representation of the message status.
        public let statusText: String

        // swift-format-ignore
        public static func == (lhs: MessageCenterViewModel.Message, rhs: MessageCenterViewModel.Message) -> Bool {
            return lhs.nonce == rhs.nonce && lhs.direction == rhs.direction && lhs.isAutomated == rhs.isAutomated && lhs.attachments == rhs.attachments && lhs.sender == rhs.sender && lhs.body == rhs.body && lhs.sentDate == rhs.sentDate
                && lhs.statusText == rhs.statusText
        }

        init(nonce: String, direction: Direction, isAutomated: Bool, attachments: [Attachment], sender: Sender?, body: String?, sentDate: Date, statusText: String, accessibilityLabel: String, accessibilityHint: String) {
            self.nonce = nonce
            self.direction = direction
            self.isAutomated = isAutomated
            self.attachments = attachments
            self.sender = sender
            self.body = body
            self.sentDate = sentDate
            self.statusText = statusText
            self.accessibilityLabel = accessibilityLabel
            self.accessibilityHint = accessibilityHint
        }

        /// Defines the status of the message whether it is an inbound message or outbound.
        public enum Direction: Equatable {
            /// The message is coming from the server.
            case sentFromDashboard(ReadStatus)
            /// The message is being sent from the device.
            case sentFromDevice(SentStatus)
        }

        /// The status of a message sent from the device.
        public enum SentStatus: Codable, Equatable {
            /// The message is a draft that is being composed.
            case draft

            /// The message is waiting to be sent, either behind other payloads, or because the device is offline.
            case queued

            /// The message is currently being transmitted to the API.
            case sending

            /// The message was sent.
            case sent

            /// The message sending attempt permanently failed.
            case failed
        }

        /// The status of a message sent to the device.
        public enum ReadStatus: Codable, Equatable {
            /// The message has been displayed to the user.
            case read

            /// The message has not yet been displayed to the user.
            case unread
        }

        /// The information associated with the sender of the message.
        public struct Sender: Equatable {
            /// The sender's name.
            var name: String?

            /// The profile photo of the sender if available.
            var profilePhotoURL: URL?
        }

        /// An attachment that can be associated with a message.
        public class Attachment: NSObject, QLPreviewItem {
            /// The file extension to show as a placeholder.
            let fileExtension: String?

            /// The thumbnail image for the attachment, if any.
            var thumbnail: UIImage?

            /// The attachment download progress from 0 to 1.
            var downloadProgress: Float

            /// The file URL on the device where the attachment is cached.
            var localURL: URL?

            internal init(fileExtension: String?, thumbnailData: Data?, localURL: URL?, downloadProgress: Float) {
                self.fileExtension = fileExtension
                self.thumbnail = thumbnailData.flatMap { UIImage(data: $0) }
                self.localURL = localURL
                self.downloadProgress = downloadProgress
            }

            internal init(localURL: URL) {
                self.fileExtension = localURL.pathExtension
                self.localURL = localURL
                self.downloadProgress = 1
            }

            /// The friendly name of the attachment (whose actual filename has a UUID prepended to it).
            public var displayName: String {
                return self.localURL.flatMap({ AttachmentManager.friendlyFilename(for: $0) }) ?? "Attachment"
            }

            /// The URL for the `QLPreviewController` to use to preview the attachment.
            public var previewItemURL: URL? {
                return self.localURL
            }

            /// The title for the `QLPreviewController` to display for the attachment.
            public var previewItemTitle: String? {
                return self.displayName
            }

            public override var accessibilityLabel: String? {
                get {
                    return self.displayName
                }
                set {}
            }

            /// The `accessibilityLabel` to associate with the button that removes the attachment from a draft message.
            public var removeButtonAccessibilityLabel: String {
                "Remove \(self.displayName)"
            }

            /// The `accessibilityLabel` to associate with the control that presents a detailed view of the attachment.
            public var viewButtonAccessibilityLabel: String {
                "View \(self.displayName)"
            }
        }
    }
}
