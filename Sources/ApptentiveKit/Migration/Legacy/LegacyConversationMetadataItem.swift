//
//  LegacyConversationMetadataItem.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/29/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveConversationMetadataItem)
class LegacyConversationMetadataItem: NSObject, NSSecureCoding {
    static var supportsSecureCoding = true

    let state: ConversationState?
    let identifier: String?
    let localIdentifier: String?
    let directoryName: String?
    let jwt: String?

    func encode(with coder: NSCoder) {
        apptentiveCriticalError("Saving legacy conversation metadata item not supported.")
    }

    required init?(coder: NSCoder) {
        self.state = ConversationState(rawValue: coder.decodeInteger(forKey: NSCodingKey.state))
        self.identifier = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.identifier) as String?
        self.localIdentifier = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.localIdentifier) as String?
        self.directoryName = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.directoryName) as String?
        self.jwt = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.jwt) as String?
    }

    struct NSCodingKey {
        static let state = "state"
        static let identifier = "conversationIdentifier"
        static let localIdentifier = "conversationLocalIdentifier"
        static let directoryName = "fileName"
        static let jwt = "JWT"
    }

    enum ConversationState: Int {
        case undefined = 0
        case anonymousPending
        case legacyPending
        case anonymous
        case loggedIn
        case loggedOut
    }
}
