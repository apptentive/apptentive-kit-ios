//
//  TextModalViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

typealias TextModalInteractionDelegate = EventEngaging & InvocationInvoking & ResponseRecording

/// Describes the values needed to configure a view for the TextModal ("Note") interaction.
public class TextModalViewModel: AlertViewModel {
    let interaction: Interaction
    let interactionDelegate: TextModalInteractionDelegate

    /// The "Do you love this app" question part of the dialog.
    public let title: String?

    /// The "subtitle" of the dialog (which should be blank).
    public let message: String?

    /// The "yes" and "no" buttons for the dialog.
    public let buttons: [AlertButtonModel]

    required init(configuration: TextModalConfiguration, interaction: Interaction, interactionDelegate: TextModalInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate

        self.title = configuration.title
        self.message = configuration.body
        self.buttons = configuration.actions.enumerated().map { (index, action) in

            AlertButtonModel(title: action.label, style: .default) {

                var textModalAction = TextModalAction(label: action.label, position: index, invokedInteractionID: nil, actionID: action.id)
                TextModalViewModel.recordResponse(textModalAction: textModalAction, delegate: interactionDelegate, interaction: interaction)

                switch action.actionType {
                case .dismiss:
                    interactionDelegate.engage(event: .dismiss(for: interaction, action: textModalAction))

                case .interaction:

                    guard let invocations = action.invocations else {
                        ApptentiveLogger.engagement.error("TextModal interaction button missing invocations.")
                        return apptentiveCriticalError("TextModal interaction button missing invocations.")
                    }

                    interactionDelegate.invoke(invocations) { (invokedInteractionID) in
                        if let invokedInteractionID = invokedInteractionID {
                            textModalAction.invokedInteractionID = invokedInteractionID
                            interactionDelegate.engage(event: .interaction(for: interaction, action: textModalAction))
                        }
                    }
                }
            }
        }
    }

    static func recordResponse(textModalAction: TextModalAction, delegate: ResponseRecording, interaction: Interaction) {
        let id = interaction.id
        let actionID = textModalAction.actionID
        let response = QuestionResponse.answered([Answer.choice(actionID)])
        delegate.recordResponse(response, for: id)
    }

    /// Engages a launch event for the interaction.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))
        self.interactionDelegate.resetCurrentResponse(for: self.interaction.id)
    }

    /// Engages a cancel event for the interaction (not used by the default implementation).
    public func cancel() {
        self.interactionDelegate.engage(event: .cancel(from: self.interaction))
    }
}

extension Event {
    static func interaction(for interaction: Interaction, action: TextModalAction) -> Self {
        var result = Event(internalName: "interaction", interaction: interaction)

        result.userInfo = .textModalAction(action)

        return result
    }

    static func dismiss(for interaction: Interaction, action: TextModalAction) -> Self {
        var result = Event(internalName: "dismiss", interaction: interaction)

        result.userInfo = .textModalAction(action)

        return result
    }
}

struct TextModalAction: Codable, Equatable {
    let label: String
    let position: Int
    var invokedInteractionID: String?
    let actionID: String

    enum CodingKeys: String, CodingKey {
        case label
        case position
        case invokedInteractionID = "invoked_interaction_id"
        case actionID = "action_id"
    }
}
