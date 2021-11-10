//
//  MessageContents.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/20/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct MessageContents: Equatable, Codable, PayloadEncodable {
    let customData: CustomData
    let isAutomated: Bool
    let isHidden: Bool
    let body: String?
    let attachments: [Message.Attachment]

    internal init(with message: Message) {
        self.customData = message.customData
        self.isAutomated = message.isAutomated
        self.isHidden = message.isHidden
        self.body = message.body

        self.attachments = message.attachments
    }

    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws {
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

    /// Creates a new object using data from the decoder.
    ///
    /// This implementation is intended for testing only.
    /// The synthesized `Decodable` conformance would fail to decode because the attachments
    /// are not encoded as part of the object.
    /// - Parameter decoder: The decoder to request data from.
    /// - Throws: an error if the coding keys are invalid or a value cannot be decoded.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.customData = try container.decode(CustomData.self, forKey: .customData)
        self.isAutomated = try container.decode(Bool.self, forKey: .isAutomated)
        self.isHidden = try container.decode(Bool.self, forKey: .isHidden)
        self.body = try container.decode(String.self, forKey: .body)
        self.attachments = []
    }

    var attachmentBodyParts: [HTTPBodyPart] {
        self.attachments.compactMap { attachment in
            guard let data = attachment.data else {
                assertionFailure("Outgoing message attachment has nil data")
                return nil
            }

            return .raw(data, mediaType: attachment.mediaType, filename: attachment.filename)
        }
    }
}
