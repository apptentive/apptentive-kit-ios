//
//  LegacyConversationMetadata.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/29/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@objc(ApptentiveConversationMetadata)
class LegacyConversationMetadata: NSObject, NSSecureCoding {
    static var supportsSecureCoding = true

    let items: [LegacyConversationMetadataItem]

    func encode(with coder: NSCoder) {}

    required init?(coder: NSCoder) {
        self.items = coder.decodeObject(of: [NSMutableArray.self, LegacyConversationMetadataItem.self], forKey: "items") as? [LegacyConversationMetadataItem] ?? []
    }
}
