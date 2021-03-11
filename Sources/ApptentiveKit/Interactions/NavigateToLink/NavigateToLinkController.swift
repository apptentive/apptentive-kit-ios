//
//  NavigateToLinkController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class NavigateToLinkController {
    let configuration: NavigateToLinkConfiguration
    let interaction: Interaction
    let delegate: EventEngaging & URLOpening

    init(configuration: NavigateToLinkConfiguration, interaction: Interaction, delegate: EventEngaging & URLOpening) {
        self.configuration = configuration
        self.interaction = interaction
        self.delegate = delegate
    }

    func navigateToLink() {
        self.delegate.open(self.configuration.url) { (success) in
            self.delegate.engage(event: .navigate(to: self.configuration.url, success: success, interaction: self.interaction))
        }
    }
}

extension Event {
    static func navigate(to url: URL, success: Bool, interaction: Interaction) -> Self {
        var event = Self.init(internalName: "navigate")

        event.userInfo = .navigateToLink(NavigateToLinkResult(url: url, success: success))
        event.interaction = interaction

        return event
    }
}

struct NavigateToLinkResult: Codable, Equatable {
    let url: URL
    let success: Bool
}
