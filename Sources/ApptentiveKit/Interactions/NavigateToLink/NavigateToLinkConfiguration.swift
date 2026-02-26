//
//  NavigateToLinkConfiguration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct NavigateToLinkConfiguration: Decodable, Equatable {
    let url: URL
    let modeConfiguration: Mode?

    var mode: Mode {
        self.modeConfiguration ?? .systemBrowser
    }

    // TODO: Update with final version of mode is selected
    enum Mode: String, Decodable {
        case systemBrowser = "new"
        case inAppBrowser = "self"
    }

    enum CodingKeys: String, CodingKey {
        case url
        case modeConfiguration = "target"
    }
}
