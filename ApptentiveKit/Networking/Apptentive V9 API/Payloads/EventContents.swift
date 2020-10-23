//
//  EventContents.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Encodes an event so that it can be sent as a payload.
struct EventContents: Equatable, Decodable, PayloadEncodable {

    /// The event label.
    let label: String

    /// Creates a new payload encodable object to represent an event.
    /// - Parameter event: The event to represent.
    init(event: Event) {
        self.label = event.codePointName
    }

    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws {
        try container.encode(self.label, forKey: .label)
    }
}
