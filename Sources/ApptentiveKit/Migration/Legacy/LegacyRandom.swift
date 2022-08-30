//
//  LegacyRandom.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/10/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveRandom)
class LegacyRandom: NSObject, NSSecureCoding {
    let randomValues: [String: Double]?

    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {
        apptentiveCriticalError("Saving legacy random is not supported")
    }

    required init?(coder: NSCoder) {
        if let randomValues = coder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: NSCodingKeys.randomValues) as? [String: Double]? {
            self.randomValues = randomValues
        } else {
            self.randomValues = nil
        }
    }

    struct NSCodingKeys {
        static let randomValues = "random_values"
    }
}
