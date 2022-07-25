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
    static var preferredStatusBarStyle: UIStatusBarStyle = .default

    // swift-format-ignore
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return Self.preferredStatusBarStyle
    }
}

extension UITableView {
    /// Determines height of the separator between questions.
    public static var apptentiveQuestionSeparatorHeight: CGFloat = {
        return 0
    }()
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

extension UIModalPresentationStyle {
    /// The modal presentation style to use for Surveys and Message Center.
    public static var apptentive: Self = .pageSheet
}

extension UIBarButtonItem {
    /// The bar button item to use for closing Apptentive UI.
    ///
    /// Defaults to the system cancel button on iOS 12 and the system close button on iOS 13 and later.
    @objc public static var apptentiveClose: UIBarButtonItem = {
        if #available(iOS 13.0, *) {
            return UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
        } else {
            return UIBarButtonItem(barButtonSystemItem: .cancel, target: nil, action: nil)
        }
    }()

    /// The bar button item to use for editing the profile in message center.
    @objc public static var apptentiveProfileEdit: UIBarButtonItem = {
        let image: UIImage? = .apptentiveImage(named: "person.crop.circle")
        let barButtonItem = UIBarButtonItem(image: image, style: .done, target: nil, action: nil)
        return barButtonItem

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
    /// The image to use for the add attachment button for message center.
    @objc public static var apptentiveMessageAttachmentButton: UIImage? = {
        return apptentiveImage(named: "paperclip.circle.fill")
    }()

    /// The image to use for the button that sends messages for message center.
    @objc public static var apptentiveMessageSendButton: UIImage? = {
        return apptentiveImage(named: "paperplane.circle.fill")
    }()

    /// The image to use as the chat bubble for outbound messages.
    @objc public static var apptentiveSentMessageBubble: UIImage? = {
        return UIImage(named: "messageSentBubble", in: .module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: 9, left: 9, bottom: 18, right: 18))
    }()

    /// The image to use as the chat bubble for inbound messages.
    @objc public static var apptentiveReceivedMessageBubble: UIImage? = {
        return UIImage(named: "messageReceivedBubble", in: .module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate).resizableImage(withCapInsets: UIEdgeInsets(top: 9, left: 18, bottom: 18, right: 9))
    }()

    /// The image to use for attachment placeholders in messages and the composer.
    @objc public static var apptentiveAttachmentPlaceholder: UIImage? = {
        return UIImage(named: "document", in: .module, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal).resizableImage(withCapInsets: UIEdgeInsets(top: 14, left: 4, bottom: 4, right: 14))
    }()

    /// The image to use for the attachment delete button.
    @objc public static var apptentiveAttachmentRemoveButton: UIImage? = {
        return .apptentiveImage(named: "minus.circle.fill")
    }()

    /// The image to use for the top navigation bar for surveys.
    @objc public static var apptentiveHeaderLogo: UIImage? = {
        return nil
    }()

    /// The image to use next to a radio button question choice.
    @objc public static var apptentiveRadioButton: UIImage? = {
        return apptentiveImage(named: "circle")
    }()

    /// The image to use next to a checkbox question choice.
    @objc public static var apptentiveCheckbox: UIImage? = {
        return apptentiveImage(named: "square")
    }()

    /// The image to use next to a selected radio button question choice.
    @objc public static var apptentiveRadioButtonSelected: UIImage? = {
        return apptentiveImage(named: "smallcircle.fill.circle.fill")
    }()

    /// The image to use next to a selected checkbox question choice.
    @objc public static var apptentiveCheckboxSelected: UIImage? = {
        return apptentiveImage(named: "checkmark.square.fill")
    }()

    static func apptentiveImage(named: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            if let result = UIImage(systemName: named) {
                return result
            }
        }

        return UIImage(named: named, in: .module, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
}

extension UIColor {

    /// The color to use for the background in text inputs for message center.
    @objc public static var apptentiveMessageCenterTextInputBackground: UIColor = {
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

    /// The placeholder color to use for text inputs for message center.
    @objc public static var apptentiveMessageCenterTextInputPlaceholder: UIColor = {
        if #available(iOS 13.0, *) {
            return .placeholderText
        } else {
            return UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 74.0 / 255.0)
        }
    }()

    /// The text color to use for all text inputs in message center.
    @objc public static var apptentiveMessageCenterTextInput: UIColor = {
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

    /// The tint color for text inputs for surveys.
    @objc public static var apptentivetextInputTint: UIColor = {
        if let tintColor = UIApplication.shared.keyWindow?.rootViewController?.view.tintColor {
            return tintColor
        } else {
            return .systemBlue
        }
    }()

    /// The border color to use for the message text view.
    @objc public static var apptentiveMessageCenterTextInputBorder: UIColor = {
        return .darkGray
    }()

    /// The color to use for the attachment button for the compose view for message center.
    @objc public static var apptentiveMessageCenterAttachmentButton: UIColor = {
        return .blue
    }()

    /// The color to use for the text view placeholder for the compose view for message center.
    @objc public static var apptentiveMessageTextInputPlaceholder: UIColor = {
        return .lightGray
    }()

    /// The color to use for the status message in message center.
    @objc public static var apptentiveMessageCenterStatus: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }()

    /// The color to use for the greeting body on the greeting header view for message center.
    @objc public static var apptentiveMessageCenterGreetingBody: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }()

    /// The color to use for the greeting title on the greeting header view for message center.
    @objc public static var apptentiveMessageCenterGreetingTitle: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }()

    /// The color to use for the message bubble view for inbound messages.
    @objc public static var apptentiveMessageBubbleInbound: UIColor = {
        return .darkGray
    }()

    /// The color to use for the message bubble view for outbound messages.
    @objc public static var apptentiveMessageBubbleOutbound: UIColor = {
        return UIColor(red: 0, green: 0.42, blue: 1, alpha: 1)
    }()

    /// The color to use for message labels for the inbound message body.
    @objc public static var apptentiveMessageLabelInbound: UIColor = {
        return .white
    }()

    /// The color to use for message labels for the outbound message body.
    @objc public static var apptentiveMessageLabelOutbound: UIColor = {
        return .white
    }()

    /// The color to use for labels in a non-error state.
    @objc public static var apptentiveQuestionLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for instruction labels.
    @objc public static var apptentiveInstructionsLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .lightGray
        }
    }()

    /// The color to use for choice labels.
    @objc public static var apptentiveChoiceLabel: UIColor = {
        return .darkGray
    }()

    /// The color to use for UI elements to indicate an error state.
    @objc public static var apptentiveError: UIColor = {
        let lightModeError = UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1)
        let darkModeError = UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1)

        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return darkModeError

                default:
                    return lightModeError
                }
            }
        } else {
            return lightModeError
        }
    }()

    /// An alternative to 'apptentiveLabel' in gray.
    @objc public static var apptentiveSecondaryLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .gray
        }
    }()

    /// The border color to use for the segmented control for range surveys.
    @objc public static var apptentiveRangeControlBorder: UIColor = {
        return .clear
    }()

    /// The color to use for the survey introduction text.
    @objc public static var apptentiveSurveyIntroduction: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for the borders of text fields and text views.
    @objc public static var apptentiveTextInputBorder: UIColor = {
        return lightGray
    }()

    /// The color to use for text fields and text views.
    @objc public static var apptentiveTextInputBackground: UIColor = {
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
    @objc public static var apptentiveTextInput: UIColor = {
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

    /// The color to use for the placeholder text within text fields and text views.
    @objc public static var apptentiveTextInputPlaceholder: UIColor = {
        if #available(iOS 13.0, *) {
            return .placeholderText
        } else {
            return UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 74.0 / 255.0)
        }
    }()

    /// The color used for min and max labels for the range survey.
    @objc public static var apptentiveMinMaxLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondaryLabel
        } else {
            return .darkGray
        }
    }()

    /// The color used for the background of the entire survey.
    @objc public static var apptentiveGroupedBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return .systemGroupedBackground
        } else {
            return .white
        }
    }()

    /// The color used for the cell where the survey question is located.
    @objc public static var apptentiveSecondaryGroupedBackground: UIColor = {
        if #available(iOS 13.0, *) {
            return .secondarySystemGroupedBackground
        } else {
            return .white
        }
    }()

    /// The color to use for separators in e.g. table views.
    @objc public static var apptentiveSeparator: UIColor = {
        if #available(iOS 13.0, *) {
            return .separator
        } else {
            return UIColor(red: 60.0 / 255.0, green: 60.0 / 255.0, blue: 67.0 / 255.0, alpha: 74.0 / 255.0)
        }
    }()

    /// The color to use for images in a selected state for surveys.
    @objc public static var apptentiveImageSelected: UIColor = {
        return UIApplication.shared.windows.first?.tintColor ?? .systemBlue
    }()

    /// The color to use for images in a non-selected state for surveys.
    @objc public static var apptentiveImageNotSelected: UIColor = {
        return UIApplication.shared.windows.first?.tintColor ?? .systemBlue
    }()

    /// The background color to use for the submit button on surveys.
    @objc public static var apptentiveSubmitButton: UIColor = {
        if let tintColor = UIApplication.shared.keyWindow?.rootViewController?.view.tintColor {
            return tintColor
        } else {
            return .systemBlue
        }
    }()

    /// The color to use for the survey footer label (Thank You text).
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveSubmitStatusLabel'.")
    public static var apptentiveSubmitLabel: UIColor = {
        return .apptentiveSubmitStatusLabel
    }()

    /// The color to use for the survey footer label (Thank You text).
    @objc public static var apptentiveSubmitStatusLabel: UIColor = {
        if #available(iOS 13.0, *) {
            return .label
        } else {
            return .black
        }
    }()

    /// The color to use for the terms of service label.
    @objc public static var apptentiveTermsOfServiceLabel: UIColor = {
        if let tintColor = UIApplication.shared.keyWindow?.rootViewController?.view.tintColor {
            return tintColor
        } else {
            return .systemBlue
        }
    }()

    /// The color to use for the submit button text color.
    @objc public static var apptentiveSubmitButtonTitle: UIColor = {
        return .white
    }()

    /// The color to use for submit button border.
    public static var apptentiveSubmitButtonBorder: UIColor = {
        return .clear
    }()

    /// The color to use for the space between questions.
    public static var apptentiveQuestionSeparator: UIColor = {
        return .clear
    }()
}

extension UIFont {

    /// The font to use for placeholder for text inputs in message center.
    @objc public static var apptentiveMessageCenterTextInputPlaceholder: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for text inputs in message menter.
    @objc public static var apptentiveMessageCenterTextInput: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for placeholder text for text inputs in surveys.
    @objc public static var apptentiveTextInputPlaceholder: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for the greeting title for message center.
    @objc public static var apptentiveMessageCenterStatus: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font to use for the greeting title for message center.
    @objc public static var apptentiveMessageCenterGreetingTitle: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font to use for the greeting body for message center.
    @objc public static var apptentiveMessageCenterGreetingBody: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font to use for attachment placeholder file extension labels.
    @objc public static var apptentiveMessageCenterAttachmentLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption1)
    }()

    /// The font used for all survey question labels.
    @objc public static var apptentiveQuestionLabel: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font used for the terms of service.
    @objc public static var apptentiveTermsOfServiceLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font used for all survey answer choice labels.
    @objc public static var apptentiveChoiceLabel: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font used for the message body in message center.
    @objc public static var apptentiveMessageLabel: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()

    /// The font used for the min and max labels for the range survey.
    @objc public static var apptentiveMinMaxLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font used for the sender label in message center.
    @objc public static var apptentiveSenderLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption2)
    }()

    /// The font used for the message date label in message center.
    @objc public static var apptentiveMessageDateLabel: UIFont = {
        return .preferredFont(forTextStyle: .caption2)
    }()

    /// The font used for the instructions label for surveys.
    @objc public static var apptentiveInstructionsLabel: UIFont = {
        return .preferredFont(forTextStyle: .footnote)
    }()

    /// The font used for the survey introduction label.
    @objc public static var apptentiveSurveyIntroductionLabel: UIFont = {
        return .preferredFont(forTextStyle: .subheadline)
    }()

    /// The font used for the survey footer label (Thank You text).
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveSubmitStatusLabel'.")
    public static var apptentiveSubmitLabel: UIFont = {
        return .apptentiveSubmitStatusLabel
    }()

    /// The font used for the survey footer label (Thank You text).
    @objc public static var apptentiveSubmitStatusLabel: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font used for the submit button at the end of surveys.
    @objc public static var apptentiveSubmitButtonTitle: UIFont = {
        return .preferredFont(forTextStyle: .headline)
    }()

    /// The font used for the multi- and single-line text inputs in surveys.
    @objc public static var apptentiveTextInput: UIFont = {
        return .preferredFont(forTextStyle: .body)
    }()
}

extension UIToolbar {
    /// The circumstances under which to show a toolbar.
    @objc public enum ToolbarMode: Int {

        /// Always show the toolbar.
        case alwaysShown

        /// Show the toolbar only when there will be UI present in it.
        case hiddenWhenEmpty
    }

    /// Determines when to show a toolbar in Apptentive view controllers.
    @objc public static var apptentiveMode: ToolbarMode = .hiddenWhenEmpty
}

extension CGFloat {
    /// The width of the layer border for Apptentive buttons.
    public static var apptentiveButtonBorderWidth: CGFloat = {
        return 2
    }()
}
