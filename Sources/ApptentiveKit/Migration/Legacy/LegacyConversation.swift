//
//  LegacyConversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveMutableConversation)
class LegacyConversation: NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    let engagement: LegacyEngagement?
    let person: LegacyPerson?
    let device: LegacyDevice?
    let random: LegacyRandom?

    func encode(with coder: NSCoder) {}

    required init?(coder: NSCoder) {
        self.engagement = coder.decodeObject(of: LegacyEngagement.self, forKey: NSCodingKeys.engagement)
        self.person = coder.decodeObject(of: LegacyPerson.self, forKey: NSCodingKeys.person)
        self.device = coder.decodeObject(of: LegacyDevice.self, forKey: NSCodingKeys.device)
        self.random = coder.decodeObject(of: LegacyRandom.self, forKey: NSCodingKeys.random)
    }

    struct NSCodingKeys {
        static let engagement = "engagement"
        static let person = "person"
        static let device = "device"
        static let random = "random"
    }
}
