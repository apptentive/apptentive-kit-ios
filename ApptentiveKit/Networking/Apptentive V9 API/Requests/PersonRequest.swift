//
//  PersonRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct PersonRequest: Codable, Equatable {
    let name: String?
    let emailAddress: String?
    let mParticleID: String?
    let customData: CustomData

    init(person: Person) {
        self.name = person.name
        self.emailAddress = person.emailAddress
        self.mParticleID = person.mParticleID
        self.customData = person.customData
    }

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case emailAddress = "email"
        case mParticleID = "mparticle_id"
        case customData = "custom_data"
    }
}
