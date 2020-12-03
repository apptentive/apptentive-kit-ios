//
//  TextModalViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Describes the values needed to configure a view for the TextModal ("Note") interaction.
public class TextModalViewModel: AlertViewModel {
    let interaction: Interaction
    let sender: ResponseSending

    /// The "Do you love this app" question part of the dialog.
    public let title: String?

    /// The "subtitle" of the dialog (which should be blank).
    public let message: String?

    /// The "yes" and "no" buttons for the dialog.
    public let buttons: [AlertButtonModel]

    required init(configuration: TextModalConfiguration, interaction: Interaction, sender: ResponseSending) {
        self.interaction = interaction
        self.sender = sender

        self.title = configuration.title
        self.message = configuration.body
        self.buttons = configuration.actions.map { action in
            AlertButtonModel(title: action.label, style: .default) {
                if let event = action.event {
                    sender.engage(event: Event(internalName: event, interaction: interaction))
                }
            }
        }
    }

    /// Engages a launch event for the interaction.
    public func launch() {
        self.sender.engage(event: .launch(from: self.interaction))
    }

    /// Engages a cancel event for the interaction (not used by the default implementation).
    public func cancel() {
        self.sender.engage(event: .cancel(from: self.interaction))
    }
}
