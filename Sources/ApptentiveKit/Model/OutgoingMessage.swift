//
//  OutgoingMessage.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents an individual message within a list of messages.
struct OutgoingMessage: Codable, Equatable {
    /// The sender information associated with the message.
    var body: String?
    /// The set of media attachments associated with the message.
    var attachments: [Payload.Attachment]
    /// When when the message was created.
    var customData: CustomData?
    /// Indicates whether the message is a Context Message (shown after a "Don't Love" response triggered Message Center).
    var isAutomated: Bool
    /// Indicates whether the message shows in the message list to the consumer.
    var isHidden: Bool

    internal init(body: String? = nil, attachments: [Payload.Attachment] = [], customData: CustomData? = nil, isAutomated: Bool = false, isHidden: Bool = false) {
        self.body = body
        self.attachments = attachments
        self.customData = customData
        self.isAutomated = isAutomated
        self.isHidden = isHidden
    }
}
