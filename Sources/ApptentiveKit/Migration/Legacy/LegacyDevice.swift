//
//  LegacyDevice.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/10/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveDevice)
class LegacyDevice: NSObject, NSSecureCoding {
    let customData: [String: Any]?

    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with coder: NSCoder) {}

    required init?(coder: NSCoder) {
        if let customData = coder.decodeObject(of: [NSDictionary.self, NSString.self, NSNumber.self], forKey: NSCodingKeys.customData) as? [String: Any]? {
            self.customData = customData
        } else {
            self.customData = nil
        }
    }

    struct NSCodingKeys {
        static let customData = "customData"
    }
}
