//
//  PersonContent.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/3/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct PersonContent: Equatable, Codable, PayloadEncodable {
    let name: String?
    let emailAddress: String?
    let mParticleID: String?
    let customData: CustomData

    init(with person: Person) {
        self.name = person.name
        self.emailAddress = person.emailAddress
        self.mParticleID = person.mParticleID
        self.customData = person.customData
    }

    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
        try container.encode(self.name, forKey: .name)
        try container.encode(self.emailAddress, forKey: .emailAddress)
        try container.encode(self.mParticleID, forKey: .mParticleID)
        try container.encode(self.customData, forKey: .customData)
    }

    func differs(from other: PersonContent, includeCustomData: Bool = true) -> Bool {
        return self.name != other.name
            || self.emailAddress != other.emailAddress
            || self.mParticleID != other.mParticleID
            || (includeCustomData && self.customData != other.customData)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case emailAddress = "email"
        case mParticleID = "mparticle_id"
        case customData = "custom_data"
    }
}
