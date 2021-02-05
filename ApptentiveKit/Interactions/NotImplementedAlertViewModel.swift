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
        self.title = NSLocalizedString("NotImplementedAlertTitle", tableName: "Localizable", bundle: Bundle(for: Apptentive.self), value: "Interaction Presenter Error", comment: "The title for the 'Not Implemented' alert.")
        self.message = String(
            format: NSLocalizedString("NotImplementedAlertMessage", tableName: "Localizable", bundle: Bundle(for: Apptentive.self), value: "Interaction '%@' is not implemented.", comment: "The message for the 'Not Implemented' alert."),
            interactionTypeName)
        self.buttons = [
            AlertButtonModel(
                title: NSLocalizedString("NotImplementedAlertConfirmation", tableName: "Localizable", bundle: Bundle(for: Apptentive.self), value: "Ok", comment: "The confimation message on the button for the 'Not Implemented' alert."), style: .default,
                action: nil)
        ]
    }
}
