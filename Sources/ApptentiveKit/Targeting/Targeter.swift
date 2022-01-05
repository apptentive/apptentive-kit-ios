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
        if let identifier = try interactionIdentifier(for: event, state: state) {
            return interactionIndex[identifier]
        } else {
            return nil
        }
    }

    func interactionData(for invocations: [EngagementManifest.Invocation], state: TargetingState) throws -> Interaction? {
        if let identifier = try interactionIdentifier(for: invocations, state: state) {
            return interactionIndex[identifier]
        } else {
            return nil
        }
    }

    /// Builds a dictionary of interactions indexed by interaction ID.
    private func buildInteractionIndex() {
        interactionIndex = Dictionary(uniqueKeysWithValues: engagementManifest.interactions.map { ($0.id, $0) })
    }

    /// Returns the interaction (if any) that should be presented when the given event is engaged.
    /// - Parameters:
    ///   - event: The event being engaged.
    ///   - state: The source of field values when evaluating criteria.
    /// - Throws: An error if criteria evaluation fails.
    /// - Returns: The interaction to present, if any.
    private func interactionIdentifier(for event: Event, state: TargetingState) throws -> String? {
        if let invocations = engagementManifest.targets[event.codePointName] {
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

    private var interactionIndex = [String: Interaction]()
}
