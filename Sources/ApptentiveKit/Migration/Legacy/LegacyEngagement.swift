//
//  LegacyEngagement.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveEngagement)
class LegacyEngagement: NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    let interactions: [String: LegacyCount]
    let codePoints: [String: LegacyCount]

    func encode(with coder: NSCoder) {}

    required init?(coder: NSCoder) {
        self.interactions = coder.decodeObject(of: [NSMutableDictionary.self, LegacyCount.self, NSString.self], forKey: NSCodingKeys.interactions) as? [String: LegacyCount] ?? [:]
        self.codePoints = coder.decodeObject(of: [NSMutableDictionary.self, LegacyCount.self, NSString.self], forKey: NSCodingKeys.codePoints) as? [String: LegacyCount] ?? [:]
    }

    struct NSCodingKeys {
        static let interactions = "interactions"
        static let codePoints = "codePoints"
    }
}
