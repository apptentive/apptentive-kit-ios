//
//  EngagementManifestShim.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/1/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// This is a (hopefully) temporary adapter that takes a Apptentive V11 API engagement manifest
/// and updates the TextModal (Note) interactions so that the actions (buttons) engage an event
/// (named `button_<interaction_id>` rather than having to evaluate a list of invocations
/// (which, incidentally, always consist of at most one interaction with empty criteria).
///
/// The invocations are then copied to the targets section under the event's code point name.
/// The end result is that the same invocations get evaluated, but we don't need a special code
/// path to make it happen, we just engage an event on the button tap like we do for the Love Dialog.
///
/// This should be removed once the API can send us pre-transfored engagement manifests.
/// - Parameter input: The engagement manifest to transform.
/// - Returns: The transformed engagement manifest.
func transformEngagementManifest(_ input: EngagementManifest) -> EngagementManifest {
    var targets = input.targets

    let interactions = input.interactions.map { (interaction) -> Interaction in
        let (newInteraction, newTargets) = processInteraction(interaction)

        targets.merge(newTargets) { (new, _) in new }

        return newInteraction
    }

    return EngagementManifest(interactions: interactions, targets: targets, expiry: input.expiry)
}

func processInteraction(_ interaction: Interaction) -> (Interaction, [String: [EngagementManifest.Invocation]]) {
    guard case let Interaction.InteractionConfiguration.textModal(configuration) = interaction.configuration else {
        return (interaction, [:])  // Skip any interactions that aren't TextModals.
    }

    var newTargets = [String: [EngagementManifest.Invocation]]()

    let newActions = configuration.actions.map { action -> TextModalConfiguration.Action in
        guard let invocations = action.invocations, action.event == nil else {
            return action  // Skip any actions that don't have invocations or already have an event.
        }

        let event = Event.init(internalName: "button_\(action.id)", interaction: interaction)
        newTargets[event.codePointName] = invocations

        return TextModalConfiguration.Action(id: action.id, label: action.label, actionType: action.actionType, invocations: nil, event: event.name)
    }

    let newConfiguration = TextModalConfiguration(title: configuration.title, body: configuration.body, actions: newActions)

    let newInteraction = Interaction(id: interaction.id, typeName: interaction.typeName, configuration: .textModal(newConfiguration))

    return (newInteraction, newTargets)
}
