//
//  Person.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Person: Equatable, Codable {
    var name: String?
    var emailAddress: String?
    var mParticleID: String?
    var customData = CustomData()

    mutating func merge(with newer: Person) {
        self.name = newer.name ?? name
        self.emailAddress = newer.emailAddress ?? emailAddress
        self.mParticleID = newer.mParticleID ?? mParticleID

        self.customData.merge(with: newer.customData)
    }
}
