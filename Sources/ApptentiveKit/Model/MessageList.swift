//
//  MessageList.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct MessageList: Codable {
    let messages: [Message]
    let endsWith: String?
    let hasMore: Bool

    enum CodingKeys: String, CodingKey {
        case messages
        case endsWith = "ends_with"
        case hasMore = "has_more"
    }
}
