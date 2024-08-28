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
    static let supportsSecureCoding = true

    let state: ConversationState?
    let identifier: String?
    let localIdentifier: String?
    let directoryName: String?
    let jwt: String?
    let userID: String?
    let encryptionKey: Data?

    func encode(with coder: NSCoder) {}

    required init?(coder: NSCoder) {
        self.state = ConversationState(rawValue: coder.decodeInteger(forKey: NSCodingKey.state))
        self.identifier = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.identifier) as String?
        self.localIdentifier = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.localIdentifier) as String?
        self.directoryName = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.directoryName) as String?
        self.jwt = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.jwt) as String?
        self.userID = coder.decodeObject(of: NSString.self, forKey: NSCodingKey.userID) as String?
        self.encryptionKey = coder.decodeObject(of: NSData.self, forKey: NSCodingKey.encryptionKey) as Data?
    }

    struct NSCodingKey {
        static let state = "state"
        static let identifier = "conversationIdentifier"
        static let localIdentifier = "conversationLocalIdentifier"
        static let directoryName = "fileName"
        static let jwt = "JWT"
        static let userID = "userId"
        static let encryptionKey = "encryptionKey"
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
