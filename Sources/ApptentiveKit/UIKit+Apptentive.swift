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
    /// Used to work around a bug in iOS 15 beta 8 (and earlier?) where navigation/tool bars end up clear in some cases.
    static var barTintColor: UIColor? = nil
    static var preferredStatusBarStyle: UIStatusBarStyle = .default

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return Self.preferredStatusBarStyle
    }
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

    /// The image to use for the top navigation bar for surveys.
    public static var apptentiveHeaderLogo: UIImage? = {
        return nil
    }()

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
            return UIImage(named: imageName, in: Bundle.module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        }
    }
}

extension UIColor {
    /// The color to use for labels in a non-error state.
    public static var apptentiveQuestionLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for instruction labels.
    public static var apptentiveInstructionsLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .lightGray
        }
    }()

    /// The color to use for choice labels.
    public static var apptentiveChoiceLabel: UIColor = {
        return .darkGray
    }()

    /// The color to use for UI elements to indicate an error state.
    public static var apptentiveError: UIColor = {
        .systemRed
    }()

    /// An alternative to 'apptentiveLabel' in gray.
    public static var apptentiveSecondaryLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .gray
        }
    }()

    /// The border color to use for the segmented control for range surveys.
    public static var apptentiveRangeControlBorder: UIColor = {
        return .clear
    }()

    /// The color to use for the survey introduction text.
    public static var apptentiveSurveyIntroduction: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for the borders of text fields and text views.
    public static var apptentiveTextInputBorder: UIColor = {
        return lightGray
    }()

    /// The color to use for text fields and text views.
    public static var apptentiveTextInputBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return .black

                default:
                    return .white

                }
            }
        } else {
            return .white
        }
    }()

    /// The color to use for text within text fields and text views.
    public static var apptentiveTextInput: UIColor = {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return .secondaryLabel

                default:
                    return .black
                }
            }
        } else {
            return .black
        }
    }()

    public static var apptentiveTextInputPlaceholder: UIColor = {
        if #available(iOS 13.0, *) {
            return .placeholderText
        } else {
            return UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 74.0 / 255.0)
        }
    }()

    /// The color used for min and max labels for the range survey.
    public static var apptentiveMinMaxLabel: UIColor = {
        return .gray
    }()

    /// The color used for the background of the entire survey.
    public static var apptentiveGroupedBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        } else {
            return .white
        }
    }()

    /// The color used for the cell where the survey question is located.
    public static var apptentiveSecondaryGroupedBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondarySystemGroupedBackground
        } else {
            return .white
        }
    }()

    public static var apptentiveSeparator: UIColor = {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 74.0 / 255.0)
        }
    }()

    /// The color to use for images in a selected state for surveys.
    public static var apptentiveImageSelected: UIColor = {
        return UIApplication.shared.windows.first?.tintColor ?? .systemBlue
    }()

    /// The color to use for images in a non-selected state for surveys.
    public static var apptentiveImageNotSelected: UIColor = {
        return UIApplication.shared.windows.first?.tintColor ?? .systemBlue
    }()

    /// The background color to use for the submit button on surveys.
    public static var apptentiveSubmitButton: UIColor = {
        if let tintColor = UIApplication.shared.keyWindow?.rootViewController?.view.tintColor {
            return tintColor
        } else {
            return .systemBlue
        }
    }()

    /// The color to use for the footer label text for surveys.
    public static var apptentiveSubmitLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for the terms of service label.
    public static var apptentiveTermsOfServiceLabel: UIColor = {
        return .white
    }()

    /// The color to use for the submit button text color.
    public static var apptentiveSubmitButtonTitle: UIColor = {
        return .white
    }()

}

extension UIFont {
    /// The font used for all survey question labels.
    public static var apptentiveQuestionLabel: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font used for the terms of service.
    public static var apptentiveTermsOfServiceLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// the font used for all survey answer choice labels.
    public static var apptentiveChoiceLabel: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font used for the min and max labels for the range survey.
    public static var apptentiveMinMaxLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption2)
    }()

    /// The font used for the instructions label for surveys.
    public static var apptentiveInstructionsLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption1)
    }()

    /// The font used for the survey introduction label.
    public static var apptentiveSurveyIntroductionLabel: UIFont = {
        return .preferredFont(forTextStyle: .subheadline)
    }()

    /// The font used for the survey confirmation label and the survey submit button.
    public static var apptentiveSubmitLabel: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font used for the submit button at the end of surveys.
    public static var apptentiveSubmitButtonTitle: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font used for the multi- and single-line text inputs in surveys.
    public static var apptentiveTextInput: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()
}
