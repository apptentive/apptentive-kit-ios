//
//  Person.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents a person for purposes of targeting and communicating with the Apptentive API.
struct Person: Equatable, Codable {

    /// The person's name.
    var name: String?

    /// The person's email address.
    var emailAddress: String?

    /// The person's identifier in the mParticle system (if used).
    var mParticleID: String?

    /// Any custom data to be associated with the person.
    var customData = CustomData()

    /// Merges a newer person record into the current one.
    /// - Parameter newer: The newer person record.
    mutating func merge(with newer: Person) {
        self.name = newer.name ?? name
        self.emailAddress = newer.emailAddress ?? emailAddress
        self.mParticleID = newer.mParticleID ?? mParticleID

        self.customData.merge(with: newer.customData)
    }
}
