//
//  Apptentive+Debugging.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Encapsulates methods on the Apptentive class that may or may not eventually make it into the public API.
extension Apptentive {
    /// Manually presents an interaction to the user.
    /// - Parameters:
    ///   - interaction: The `Interaction` instance representing the interaction.
    ///   - presentingViewController: A view controller that will be tasked with presenting a view-controller-based interaction.
    /// - Throws: An error if the interaction is invalid or if—for view-controller-based interactions—the view controller is  either`nil` or not currently capable of presenting the view controller for the interaction.
    public func presentInteraction(_ interaction: Interaction, from presentingViewController: UIViewController) throws {
        try self.interactionPresenter.presentInteraction(interaction, from: presentingViewController)
    }

    /// Overrides the API-provided engagement manifest with one from the specified URL.
    /// - Parameter url: The (file) URL of the manifest to load.
    public func loadEngagementManifest(at url: URL?) {
        self.backendQueue.async {
            if let url = url {
                do {
                    let manifestData = try Data(contentsOf: url)

                    let engagementManifest = try JSONDecoder().decode(EngagementManifest.self, from: manifestData)

                    self.backend.targeter.localEngagementManifest = engagementManifest
                } catch let error {
                    ApptentiveLogger.engagement.error("Unable to load local manifest at \(url.absoluteString): \(error).")
                }
            } else {
                self.backend.targeter.localEngagementManifest = nil
            }
        }
    }
}
