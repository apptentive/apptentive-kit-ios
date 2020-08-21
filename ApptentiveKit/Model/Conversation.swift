//
//  Conversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Conversation {
    var appCredentials: Apptentive.AppCredentials?
    var sdkVersion: String
}

// For testing only
extension Conversation {
    init() {
        sdkVersion = "0"
    }
}
