//
//  Targeter.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

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

    func interactionData(for event: Event) throws -> Interaction? {
        if let identifier = try interactionIdentifier(for: event) {
            return interactionIndex[identifier]
        } else {
            return nil
        }
    }

    private func buildInteractionIndex() {
        interactionIndex = Dictionary(uniqueKeysWithValues: engagementManifest.interactions.map { ($0.id, $0) })
    }

    private func interactionIdentifier(for event: Event) throws -> String? {
        if let invocations = engagementManifest.targets[event.codePointName] {
            if let invocation = invocations.first {
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
