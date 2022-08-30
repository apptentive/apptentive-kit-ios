//
//  Targeter.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol TargetingState {
    func value(for field: Field) throws -> Any?
}

/// Determines which interaction (if any) to present in response to an event being engaged.
class Targeter {

    /// The engagement manifest to use for targeting and describing interactions.
    var engagementManifest: EngagementManifest {
        didSet {
            buildInteractionIndex()
        }
    }

    /// Debug/development override of the API-delivered engagement manifest.
    var localEngagementManifest: EngagementManifest? {
        didSet {
            buildInteractionIndex()
        }
    }

    var activeManifest: EngagementManifest {
        self.localEngagementManifest ?? self.engagementManifest
    }

    var interactionIndex = [String: Interaction]()

    /// Creates a new targeter with the specified engagement manifest.
    /// - Parameter engagementManifest: The engagement manifest to use for targeting and describing interactions.
    init(engagementManifest: EngagementManifest) {
        self.engagementManifest = engagementManifest
        buildInteractionIndex()
    }

    /// Returns the interaction that should be presented (if any) in response to the specified event being engaged.
    /// - Parameters:
    ///   - event: The event that was engaged.
    ///   - state: The source of field values when evaluating criteria.
    /// - Throws: An error if criteria evaluation fails.
    /// - Returns: The interaction to present, or nil if no interaction should be presented.
    func interactionData(for event: Event, state: TargetingState) throws -> Interaction? {
        return try self.interactionIdentifier(for: event, state: state).flatMap { self.interactionIndex[$0] }
    }

    func interactionData(for invocations: [EngagementManifest.Invocation], state: TargetingState) throws -> Interaction? {
        return try self.interactionIdentifier(for: invocations, state: state).flatMap { self.interactionIndex[$0] }
    }

    /// Builds a dictionary of interactions indexed by interaction ID.
    private func buildInteractionIndex() {
        interactionIndex = Dictionary(
            self.activeManifest.interactions.map { ($0.id, $0) },
            uniquingKeysWith: { old, new in
                apptentiveCriticalError("Invalid engagement manifest: Interaction IDs must be unique.")
                return old
            })
    }

    /// Returns the interaction (if any) that should be presented when the given event is engaged.
    /// - Parameters:
    ///   - event: The event being engaged.
    ///   - state: The source of field values when evaluating criteria.
    /// - Throws: An error if criteria evaluation fails.
    /// - Returns: The interaction to present, if any.
    private func interactionIdentifier(for event: Event, state: TargetingState) throws -> String? {
        if let invocations = self.activeManifest.targets[event.codePointName] {
            if let interactionID = try self.interactionIdentifier(for: invocations, state: state) {
                return interactionID
            } else {
                ApptentiveLogger.engagement.info("No interactions targeting event \(event) have criteria met by active conversation.")
                return nil
            }
        } else {
            ApptentiveLogger.engagement.info("No interactions target the event \(event).")
            return nil
        }
    }

    private func interactionIdentifier(for invocations: [EngagementManifest.Invocation], state: TargetingState) throws -> String? {

        let invocation = try invocations.first(where: { invocation in
            invocation.preLog()

            let result = try invocation.criteria.isSatisfied(for: state)

            invocation.postLog(result)

            return result
        })

        return invocation?.interactionID
    }
}
