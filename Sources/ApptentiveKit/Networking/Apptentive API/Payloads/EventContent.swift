//
//  EventContent.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Encodes an event so that it can be sent as a payload.
struct EventContent: Equatable, Decodable, PayloadEncodable {

    /// The event label.
    let label: String

    /// The ID of the interaction engaging the event, if any.
    let interactionID: String?

    /// Additional event-specific info.
    let userInfo: EventUserInfo?

    /// The event that triggered an interaction launch event, if any.
    let whereEvent: String?

    /// Custom data associated with the event.
    let customData: CustomData?

    /// Creates a new payload encodable object to represent an event.
    /// - Parameter event: The event to represent.
    init(with event: Event) {
        self.customData = event.customData.customData.isEmpty ? nil : event.customData
        self.label = event.codePointName
        self.interactionID = event.interaction?.id
        self.userInfo = event.userInfo
        self.whereEvent = event.whereEvent
    }

    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
        try container.encode(self.label, forKey: .label)
        try container.encodeIfPresent(self.interactionID, forKey: .interactionID)
        try container.encodeIfPresent(self.whereEvent, forKey: .whereEvent)
        try container.encodeIfPresent(self.customData, forKey: .customData)

        if let userInfo = self.userInfo {
            let dataEncoder = container.superEncoder(forKey: .userInfo)
            switch userInfo {
            case .navigateToLink(let link):
                try link.encode(to: dataEncoder)

            case .textModalAction(let action):
                try action.encode(to: dataEncoder)

            case .dismissCause(let cause):
                try cause.encode(to: dataEncoder)

            case .messageInfo(let info):
                try info.encode(to: dataEncoder)
            }
        }
    }

    // This should only be used for testing.
    // Items decoded with this decoder may differ from the encoded version.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.label = try container.decode(String.self, forKey: .label)
        self.interactionID = try container.decodeIfPresent(String.self, forKey: .interactionID)
        self.customData = try container.decodeIfPresent(CustomData.self, forKey: .eventCustomData)

        if self.label == "com.apptentive#NavigateToLink#navigate" {
            self.userInfo = .navigateToLink(try container.decode(NavigateToLinkResult.self, forKey: .userInfo))
        } else {
            self.userInfo = nil
        }
        self.whereEvent = nil
    }

    enum CodingKeys: String, CodingKey {
        case label
        case interactionID = "interaction_id"
        case userInfo = "data"
        case eventCustomData = "custom_data"
    }

}
