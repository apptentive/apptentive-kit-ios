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

    let token: String?
    let identifier: String?
    let engagement: LegacyEngagement?

    func encode(with coder: NSCoder) {
        assertionFailure("Saving legacy conversation is not supported")
    }

    required init?(coder: NSCoder) {
        self.token = coder.decodeObject(of: NSString.self, forKey: NSCodingKeys.token) as String?
        self.identifier = coder.decodeObject(of: NSString.self, forKey: NSCodingKeys.identifier) as String?
        self.engagement = coder.decodeObject(of: LegacyEngagement.self, forKey: NSCodingKeys.engagement)
    }

    struct NSCodingKeys {
        static let token = "token"
        static let identifier = "identifier"
        static let engagement = "engagement"
    }
}
