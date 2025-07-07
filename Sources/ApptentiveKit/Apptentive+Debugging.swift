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
    private static var engagementManifestURL: URL?

    /// The currently-set manifest override URL, if any.
    public var engagementManifestURL: URL? {
        return Self.engagementManifestURL
    }

    public enum ConversationState: String {
        case none = "None"
        case placeholder = "Placeholder"
        case anonymousPending = "Anonymous Pending"
        case legacyPending = "Legacy Pending"
        case anonymous = "Anonymous"
        case loggedIn = "Logged In"
        case loggedOut = "Logged Out"
    }

    /// Overrides the API-provided engagement manifest with one from the specified URL.
    /// - Parameter url: The (file) URL of the manifest to load.
    /// - Throws: An error if the manifest fails to load.
    public func loadEngagementManifest(at url: URL?) async throws {
        if let url = url {
            let manifestData = try Data(contentsOf: url)

            let engagementManifest = try JSONDecoder.apptentive.decode(EngagementManifest.self, from: manifestData)

            await self.backend.setLocalEngagementManifest(engagementManifest)
            await self.resourceManager.prefetchResources(at: engagementManifest.prefetch ?? [])

            Self.engagementManifestURL = url
        } else {
            await self.backend.setLocalEngagementManifest(nil)

            Self.engagementManifestURL = nil
        }
    }

    /// Returns a list of objects describing the interactions encoded in the engagement manifest.
    /// - Returns: The list of interaction items.
    public func getInteractionList() async -> [InteractionListItem] {
        return await self.backend.getInteractions()
            .map({ InteractionListItem(id: $0.id, displayName: $0.displayName, typeName: $0.typeName) })
    }

    /// Attempts to present the interaction with the specified identifier from the active engagement manifest.
    /// - Parameter id: The identifier of the interaction.
    /// - Throws: An error if the interaction fails to present.
    public func presentInteraction(with id: String) async throws {
        if let interaction = await self.backend.getInteraction(with: id) {
            try await self.interactionPresenter.presentInteraction(interaction)
        }
    }

    /// Attempts to load a JSON-encoded interaction from the specified URL and present it.
    /// - Parameter url: The URL for the interaction
    /// - Throws: An error if presenting the interaction fails.
    public func presentInteraction(at url: URL) async throws {
        let interactionData = try Data(contentsOf: url)
        let interaction = try JSONDecoder.apptentive.decode(Interaction.self, from: interactionData)

        try await self.interactionPresenter.presentInteraction(interaction)
    }

    /// An object that encapsulates the information to display an interaction in a list.
    public struct InteractionListItem {
        /// The identifier of the interaction.
        public let id: String

        /// The display name for the interaction.
        public let displayName: String

        /// The internal type name of the interaction.
        public let typeName: String
    }

    /// Calls a completion handler with a list of app-defined events that may trigger an interaction.
    /// - Parameter completion: A completion handler that is called with the list of events.
    public func getEventList(_ completion: @escaping ([String]) -> Void) {
        Task {
            let targetedEvents = await self.backend.getTargets()
                .filter({ $0.hasPrefix("local#app#") })
                .compactMap({ $0.split(separator: "#").last?.removingPercentEncoding })

            DispatchQueue.main.async {
                completion(targetedEvents)
            }
        }
    }

    /// Queries information about the current connection to the Apptentive API.
    /// - Returns: A tuple containing the conversation state, conversation ID, and conversation token.
    public func getConnectionInfo() async -> (ConversationState, String?, String?) {
        let conversationState = await self.backend.getState()

        switch conversationState {
        case .placeholder:
            return (.placeholder, nil, nil)

        case .anonymousPending:
            return (.anonymousPending, nil, nil)

        case .legacyPending:
            return (.legacyPending, nil, nil)

        case .anonymous(let credentials):
            return (.anonymous, credentials.id, credentials.token)

        case .loggedIn(let credentials, _, _):
            return (.loggedIn, credentials.id, credentials.token)

        default:
            return (.loggedOut, nil, nil)
        }
    }
}

extension Backend {
    func setLocalEngagementManifest(_ localEngagementManifest: EngagementManifest?) {
        self.targeter.localEngagementManifest = localEngagementManifest
    }

    func getInteractions() -> [Interaction] {
        return self.targeter.activeManifest.interactions
    }

    func getInteraction(with id: String) -> Interaction? {
        return self.targeter.interactionIndex[id]
    }

    func getTargets() -> [String] {
        return Array(self.targeter.activeManifest.targets.keys)
    }

    func getState() -> ConversationRoster.Record.State? {
        return self.state.roster.active?.state
    }
}

extension Interaction {
    var displayName: String {
        switch self.configuration {

        case .appleRatingDialog:
            return "Apple Rating Dialog"

        case .enjoymentDialog(let configuration):
            return String(configuration.title.characters)

        case .navigateToLink(let configuration):
            return configuration.url.absoluteString

        case .textModal(let configuration):
            return configuration.name ?? configuration.title.flatMap { String($0.characters) } ?? configuration.body.flatMap { String($0.characters) } ?? "Untitled"

        case .messageCenter(let configuration):
            return configuration.title

        case .surveyV12(let configuration):
            return configuration.title

        case .initiator:
            return "Initiator"

        case .notImplemented:
            return "Not Implemented"

        case .failedDecoding:
            return "Invalid"
        }
    }
}
