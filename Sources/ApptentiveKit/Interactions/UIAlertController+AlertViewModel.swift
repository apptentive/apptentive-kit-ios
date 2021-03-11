//
//  UIAlertController+AlertViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Describes a view model that can be used to configure a `UIAlertView`.
public protocol AlertViewModel {
    /// The title of the alert view.
    var title: String? { get }

    /// The message of the alert view.
    var message: String? { get }

    /// The buttons of the alert view.
    var buttons: [AlertButtonModel] { get }
}

/// Describes a button that can be used to configure a `UIAlertAction`.
public struct AlertButtonModel {
    /// The label of the button.
    let title: String

    /// The style of the button.
    let style: UIAlertAction.Style

    /// A closure to call when the button is tapped.
    let action: (() -> Void)?
}

extension UIAlertController {
    convenience init(viewModel: AlertViewModel) {
        self.init(title: viewModel.title, message: viewModel.message, preferredStyle: .alert)

        viewModel.buttons.forEach { self.addAction(UIAlertAction(viewModel: $0)) }
    }
}

extension UIAlertAction {
    convenience init(viewModel: AlertButtonModel) {
        self.init(
            title: viewModel.title, style: viewModel.style,
            handler: { (alertAction) in
                viewModel.action?()
            })
    }
}
