//
//  MessageContent.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/20/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct MessageContent: Equatable, Codable, PayloadEncodable {
    let customData: CustomData?
    let isAutomated: Bool
    let isHidden: Bool
    let body: String?

    internal init(with message: MessageList.Message, customData: CustomData? = nil) {
        self.customData = customData
        self.isAutomated = message.isAutomated
        self.isHidden = message.isHidden
        self.body = message.body
    }

    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
        try container.encode(self.customData, forKey: .customData)
        try container.encode(self.isAutomated, forKey: .isAutomated)
        try container.encode(self.isHidden, forKey: .isHidden)
        try container.encode(self.body, forKey: .body)
    }

    enum CodingKeys: String, CodingKey {
        case customData = "custom_data"
        case isAutomated = "automated"
        case isHidden = "hidden"
        case body
    }
}
