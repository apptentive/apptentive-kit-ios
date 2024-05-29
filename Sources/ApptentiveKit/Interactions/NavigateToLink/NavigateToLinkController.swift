//
//  NavigateToLinkController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import SafariServices
import UIKit

typealias NavigateToLinkInteractionDelegate = EventEngaging & URLOpening

class NavigateToLinkController {
    let configuration: NavigateToLinkConfiguration
    let interaction: Interaction
    let interactionDelegate: NavigateToLinkInteractionDelegate
    public let closeButtonAccessibilityLabel: String
    public let closeButtonAccessibilityHint: String

    init(configuration: NavigateToLinkConfiguration, interaction: Interaction, interactionDelegate: NavigateToLinkInteractionDelegate) {
        self.configuration = configuration
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate

        self.closeButtonAccessibilityLabel = NSLocalizedString("Web View Close Button Accessibility Label", bundle: .apptentive, value: "Close", comment: "The accessibility label for the close button.")

        self.closeButtonAccessibilityHint = NSLocalizedString("Web View Close Button Accessibility Hint", bundle: .apptentive, value: "Closes Web View", comment: "The accessibility hint for the close button.")
    }

    func navigateToLink() -> UIViewController? {
        switch configuration.mode {
        case .inAppBrowser:
            let viewController = WebViewController(viewModel: self)
            let navigationController = ApptentiveNavigationController(rootViewController: viewController)
            return navigationController

        default:
            self.interactionDelegate.open(self.configuration.url) { (success) in
                self.launch(success: success)
            }
            return nil
        }
    }

    public func launch(success: Bool) {
        self.interactionDelegate.engage(event: .navigate(to: self.configuration.url, success: success, interaction: self.interaction))
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
