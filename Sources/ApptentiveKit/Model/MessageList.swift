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
    var messages: [Message] = []
    /// The identifier associated with the last message.
    let endsWith: String?
    /// Indicates whether there are more messages.
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case messages
        case endsWith = "ends_with"
        case hasMore = "has_more"
    }

    init(messages: [Message], endsWith: String?, hasMore: Bool) {
        self.messages = messages
        self.endsWith = endsWith
        self.hasMore = hasMore
    }
}
