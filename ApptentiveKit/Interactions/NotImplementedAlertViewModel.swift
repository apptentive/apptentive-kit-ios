//
//  NotImplementedAlert.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 12/8/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Describes the values needed to implment alert for an interaction that is not yet implemented.
struct NotImplementedAlertViewModel: AlertViewModel {
    /// The title of the alert.
    var title: String?

    /// The message of the alert, which is set by default in the initializer.
    var message: String?

    /// The 'ok' button for the alert.
    var buttons: [AlertButtonModel]

    init(interactionTypeName: String) {
        self.title = "Interaction Presenter Error"
        self.message = "Interaction: '\(interactionTypeName)' is not implemented."
        self.buttons = [AlertButtonModel(title: "Ok", style: .default, action: nil)]
    }
}
