//
//  LegacyCount.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveCount)
class LegacyCount: NSObject, NSSecureCoding {
    static let supportsSecureCoding = true

    let totalCount: Int
    let versionCount: Int
    let buildCount: Int
    let lastInvoked: Date?

    func encode(with coder: NSCoder) {
        apptentiveCriticalError("Saving legacy count is not supported.")
    }

    required init?(coder: NSCoder) {
        self.totalCount = coder.decodeInteger(forKey: NSCodingKeys.totalCount)
        self.versionCount = coder.decodeInteger(forKey: NSCodingKeys.versionCount)
        self.buildCount = coder.decodeInteger(forKey: NSCodingKeys.buildCount)
        self.lastInvoked = coder.decodeObject(of: NSDate.self, forKey: NSCodingKeys.lastInvoked) as Date?
    }

    struct NSCodingKeys {
        static let totalCount = "totalCount"
        static let versionCount = "versionCount"
        static let buildCount = "buildCount"
        static let lastInvoked = "lastInvoked"
    }
}
