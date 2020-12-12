//
//  UIKit+Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/9/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// `UINavigationController` subclass intended primarily to facilitate scoping `UIAppearance` rules to Apptentive UI.
public class ApptentiveNavigationController: UINavigationController {
}

extension UITableView.Style {
    /// The table view style to use for Apptentive UI.
    ///
    /// Defaults to grouped for iOS 12 and inset grouped for iOS 13 and later.
    public static var apptentive: UITableView.Style = {
        if #available(iOS 13.0, *) {
            return .insetGrouped
        } else {
            return .grouped
        }
    }()
}

extension UIBarButtonItem {
    /// The bar button item to use for closing Apptentive UI.
    ///
    /// Defaults to the system cancel button on iOS 12 and the system close button on iOS 13 and later.
    public static var apptentiveClose: UIBarButtonItem = {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
        } else {
            return UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        }
    }()
}

extension UIButton {
    /// The style for call-to-action buttons in Apptentive UI.
    public enum ApptentiveButtonStyle {
        /// The corner radius is half of the height.
        case pill

        /// The corner radius is the associated CGFloat value.
        case radius(CGFloat)
    }

    /// The style for call-to-action buttons in Apptentive UI.
    public static var apptentiveStyle: ApptentiveButtonStyle = .pill
}

extension UIImage {
    /// The image to use next to a radio button question choice.
    public static var apptentiveRadioButton: UIImage? = {
        return apptentiveImage(named: "circle")
    }()

    /// The image to use next to a checkbox question choice.
    public static var apptentiveCheckbox: UIImage? = {
        return apptentiveImage(named: "square")
    }()

    /// The image to use next to a selected radio button question choice.
    public static var apptentiveRadioButtonSelected: UIImage? = {
        return apptentiveImage(named: "smallcircle.fill.circle.fill")
    }()

    /// The image to use next to a selected checkbox question choice.
    public static var apptentiveCheckboxSelected: UIImage? = {
        return apptentiveImage(named: "checkmark.square.fill")
    }()

    static func apptentiveImage(named imageName: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: imageName)
        } else {
            return UIImage(named: imageName, in: Bundle(for: Apptentive.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        }
    }
}

extension UIColor {
    /// The color to use for labels in a non-error state.
    public static var apptentiveLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for UI elements to indicate an error state.
    public static var apptentiveError: UIColor = {
        .systemRed
    }()

    /// The color to use for the survey introduction text.
    public static var apptentiveSurveyIntroduction: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }()
}
