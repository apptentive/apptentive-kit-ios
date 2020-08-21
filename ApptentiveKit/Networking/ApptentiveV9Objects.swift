//
//  ApptentiveV9Objects.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/12/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ConversationRequest: Encodable {
    init(conversation: Conversation) {}
}

struct ConversationResponse: Codable, Equatable {}
