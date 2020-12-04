//
//  EnjoymentDialogViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the values needed to configure a view for the EnjoymentDialog ("Love Dialog") interaction.
public class EnjoymentDialogViewModel: AlertViewModel {
    let interaction: Interaction
    let delegate: EventEngaging

    /// The "Do you love this app" question part of the dialog.
    public let title: String?

    /// The "subtitle" of the dialog (which should be blank).
    public let message: String?

    /// The "yes" and "no" buttons for the dialog.
    public let buttons: [AlertButtonModel]

    init(configuration: EnjoymentDialogConfiguration, interaction: Interaction, delegate: EventEngaging) {
        self.interaction = interaction
        self.delegate = delegate

        self.title = configuration.title
        self.message = nil
        self.buttons = [
            AlertButtonModel(
                title: configuration.yesText, style: .default,
                action: {
                    delegate.engage(event: .yes(from: interaction))
                }),
            AlertButtonModel(
                title: configuration.noText, style: .default,
                action: {
                    delegate.engage(event: .no(from: interaction))
                }),
        ]
    }

    /// Engages a launch event for the interaction.
    public func launch() {
        self.delegate.engage(event: .launch(from: self.interaction))
    }

    /// Engages a cancel event for the interaction (not used by the default implementation).
    public func cancel() {
        self.delegate.engage(event: .cancel(from: self.interaction))
    }
}

extension Event {
    static func yes(from interaction: Interaction) -> Self {
        return Self.init(internalName: "yes", interaction: interaction)
    }

    static func no(from interaction: Interaction) -> Self {
        return Self.init(internalName: "no", interaction: interaction)
    }
}
