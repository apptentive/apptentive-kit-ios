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

class Targeter {
    var engagementManifest: EngagementManifest {
        didSet {
            buildInteractionIndex()
        }
    }

    init() {
        self.engagementManifest = EngagementManifest(interactions: [], targets: [:])
    }

    init(engagementManifest: EngagementManifest) {
        self.engagementManifest = engagementManifest
        buildInteractionIndex()
    }

    func interactionData(for event: Event, state: TargetingState) throws -> Interaction? {
        if let identifier = try interactionIdentifier(for: event, state: state) {
            return interactionIndex[identifier]
        } else {
            return nil
        }
    }

    private func buildInteractionIndex() {
        interactionIndex = Dictionary(uniqueKeysWithValues: engagementManifest.interactions.map { ($0.id, $0) })
    }

    private func interactionIdentifier(for event: Event, state: TargetingState) throws -> String? {
        if let invocations = engagementManifest.targets[event.codePointName] {
            if let invocation = try invocations.first(where: { try $0.criteria.isSatisfied(for: state) }) {
                return invocation.interactionID
            } else {
                print("No interactions targeting event \(event) have criteria met by active conversation.")
                return nil
            }
        } else {
            print("No interactions target the event \(event).")
            return nil
        }
    }

    private var interactionIndex = [String: Interaction]()
}
