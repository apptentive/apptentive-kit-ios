//
//  Apptentive+DefaultAppearance.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/9/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

extension Apptentive {
    /// This callback will set the default cross-platform Apptentive look for Apptentive UI.
    func applyApptentiveTheme() {
        // UIAppearance-based overrides

        let bundle = Bundle(for: Apptentive.self)

        guard let barTintColor = UIColor(named: "barTint", in: bundle, compatibleWith: nil),
            let barForegroundColor = UIColor(named: "barForeground", in: bundle, compatibleWith: nil),
            let buttonTintColor = UIColor(named: "buttonTint", in: bundle, compatibleWith: nil)
        else {
            assertionFailure("Unable to locate color asset(s).")
            return
        }

        let barTextAttributes = [NSAttributedString.Key.foregroundColor: barForegroundColor]

        let navigationBarAppearance = UINavigationBar.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
        navigationBarAppearance.barTintColor = barTintColor
        navigationBarAppearance.titleTextAttributes = barTextAttributes
        navigationBarAppearance.isTranslucent = false

        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
        barButtonItemAppearance.setTitleTextAttributes(barTextAttributes, for: .normal)
        barButtonItemAppearance.tintColor = barForegroundColor

        UIView.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self, UITableView.self]).tintColor = buttonTintColor

        let backgroundColor: UIColor = {
            if #available(iOS 13.0, *) {
                return .systemBackground
            } else {
                return .white
            }
        }()
        let tableViewAppearance = UITableView.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])

        tableViewAppearance.backgroundColor = backgroundColor
        tableViewAppearance.separatorColor = backgroundColor

        // Apptentive UIKit extensions overrides

        UITableView.Style.apptentive = .grouped

        UIBarButtonItem.apptentiveClose = {
            let systemClose: UIBarButtonItem = {
                if #available(iOS 13.0, *) {
                    return UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
                } else {
                    return UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
                }
            }()

            let closeImage: UIImage? = {
                return .apptentiveImage(named: "xmark")
            }()

            let result = UIBarButtonItem(image: closeImage, landscapeImagePhone: closeImage, style: .plain, target: nil, action: nil)

            result.accessibilityLabel = systemClose.accessibilityLabel
            result.accessibilityHint = systemClose.accessibilityHint

            return result
        }()

        UIButton.apptentiveStyle = .radius(8.0)
    }
}
