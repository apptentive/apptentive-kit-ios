//
//  LegacyPerson.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/10/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentivePerson)
class LegacyPerson: NSObject, NSSecureCoding {
    let name: String?
    let emailAddress: String?
    let mParticleID: String?
    let customData: [String: Any]?

    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {
        assertionFailure("Saving legacy custom data is not supported")
    }

    required init?(coder: NSCoder) {
        self.name = coder.decodeObject(of: NSString.self, forKey: NSCodingKeys.name) as String?
        self.emailAddress = coder.decodeObject(of: NSString.self, forKey: NSCodingKeys.emailAddress) as String?
        self.mParticleID = coder.decodeObject(of: NSString.self, forKey: NSCodingKeys.mParticleID) as String?

        if let customData = coder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: NSCodingKeys.customData) as? [String: Any]? {
            self.customData = customData
        } else {
            self.customData = nil
        }
    }

    struct NSCodingKeys {
        static let name = "name"
        static let emailAddress = "emailAddress"
        static let mParticleID = "mParticleId"
        static let customData = "customData"
    }
}
