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
    /// Increases the header height for surveys.
    @objc public static var prefersLargeHeader: Bool = false
}

extension UITableView {
    /// Determines height of the separator between questions.
    public static var apptentiveQuestionSeparatorHeight: CGFloat = 0
}

extension UITableView.Style {
    /// The table view style to use for Apptentive UI.
    public static var apptentive: UITableView.Style = .insetGrouped
}

extension UIModalPresentationStyle {
    /// The modal presentation style to use for Surveys and Message Center.
    public static var apptentive: Self = .pageSheet
}

extension UIBarButtonItem {
    /// The bar button item to use for closing Apptentive UI.
    @objc public static var apptentiveClose: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)

    /// The bar button item to use for refreshing the Apptentive Web View.
    @objc public static var appentiveRefresh: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: nil)

    /// The bar button item to use for editing the profile in message center.
    @objc public static var apptentiveProfileEdit: UIBarButtonItem = UIBarButtonItem(image: .apptentiveImage(named: "person.crop.circle"), style: .done, target: nil, action: nil)
}

extension UIButton {

    /// The close button used to replicate the bar button item when large headers are used in surveys.
    public static var apptentiveClose: UIButton? = {
        let button = UIButton()
        button.setImage(UIImage.init(systemName: "xmark"), for: .normal)
        button.tintColor = .gray
        return button
    }()

    /// The style for call-to-action buttons in Apptentive UI.
    public enum ApptentiveButtonStyle: Equatable {
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
    @objc public static var apptentiveMessageAttachmentButton: UIImage? = apptentiveImage(named: "paperclip.circle.fill")

    /// The image to use for the button that sends messages for message center.
    @objc public static var apptentiveMessageSendButton: UIImage? = apptentiveImage(named: "paperplane.circle.fill")

    /// The image to use as the chat bubble for outbound messages.
    @objc public static var apptentiveSentMessageBubble: UIImage? = UIImage(named: "messageSentBubble", in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate).resizableImage(
        withCapInsets: UIEdgeInsets(top: 9, left: 9, bottom: 14, right: 18))

    /// The image to use as the chat bubble for inbound messages.
    @objc public static var apptentiveReceivedMessageBubble: UIImage? = UIImage(named: "messageReceivedBubble", in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate).resizableImage(
        withCapInsets: UIEdgeInsets(top: 9, left: 18, bottom: 14, right: 9))

    /// The image to use for attachment placeholders in messages and the composer.
    @objc public static var apptentiveAttachmentPlaceholder: UIImage? = UIImage(named: "document", in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysOriginal).resizableImage(
        withCapInsets: UIEdgeInsets(top: 14, left: 4, bottom: 4, right: 14))

    /// The image to use for the attachment delete button.
    @objc public static var apptentiveAttachmentRemoveButton: UIImage? = .apptentiveImage(named: "minus.circle.fill")?.withRenderingMode(.alwaysOriginal)

    /// The image to use for the top navigation bar for surveys.
    @objc public static var apptentiveHeaderLogo: UIImage? = nil

    /// The image to use next to a radio button question choice.
    @objc public static var apptentiveRadioButton: UIImage? = apptentiveImage(named: "circle")

    /// The image to use next to a checkbox question choice.
    @objc public static var apptentiveCheckbox: UIImage? = apptentiveImage(named: "square")

    /// The image to use next to a selected radio button question choice.
    @objc public static var apptentiveRadioButtonSelected: UIImage? = apptentiveImage(named: "smallcircle.fill.circle.fill")

    /// The image to use next to a selected checkbox question choice.
    @objc public static var apptentiveCheckboxSelected: UIImage? = apptentiveImage(named: "checkmark.square.fill")

    static func apptentiveImage(named: String) -> UIImage? {
        if let result = UIImage(systemName: named) {
            return result
        }

        return UIImage(named: named, in: .apptentive, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
    }
}

extension UIColor {

    /// The color to use for the background in text inputs for message center.
    @objc public static var apptentiveMessageCenterTextInputBackground = apptentiveTextInputBackground

    /// The placeholder color to use for text inputs for message center.
    @objc public static var apptentiveMessageCenterTextInputPlaceholder = apptentiveTextInputPlaceholder

    /// The placeholder color to use for text inputs for message center.
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveMessageTextInputPlaceholder'.")
    @objc public static var apptentiveMessageTextViewPlaceholder: UIColor {
        get {
            return self.apptentiveMessageTextInputPlaceholder
        }
        set {
            self.apptentiveMessageTextInputPlaceholder = newValue
        }
    }

    /// The text color to use for all text inputs in message center.
    @objc public static var apptentiveMessageCenterTextInput = apptentiveTextInput

    /// The tint color for text inputs for surveys.
    @objc public static var apptentivetextInputTint = apptentiveTint

    /// The border color to use for the message text view.
    @objc public static var apptentiveMessageCenterTextInputBorder = apptentiveTextInputBorder

    /// The border color to use for the message text view.
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveMessageCenterTextInputBorder'.")
    @objc public static var apptentiveMessageCenterTextViewBorder: UIColor {
        get {
            return self.apptentiveMessageCenterTextInputBorder
        }
        set {
            self.apptentiveMessageCenterTextInputBorder = newValue
        }
    }

    /// The color to use for the attachment button for the compose view for message center.
    @objc public static var apptentiveMessageCenterAttachmentButton = apptentiveTint

    /// The color to use for the text view placeholder for the compose view for message center.
    @objc public static var apptentiveMessageTextInputPlaceholder = apptentiveTextInputPlaceholder

    /// The color to use for the status message in message center.
    @objc public static var apptentiveMessageCenterStatus = apptentiveSecondaryLabel

    /// The color to use for the greeting body on the greeting header view for message center.
    @objc public static var apptentiveMessageCenterGreetingBody = apptentiveSecondaryLabel

    /// The color to use for the greeting title on the greeting header view for message center.
    @objc public static var apptentiveMessageCenterGreetingTitle = apptentiveSecondaryLabel

    /// The color to use for the message bubble view for inbound messages.
    @objc public static var apptentiveMessageBubbleInbound = darkGray

    /// The color to use for the message bubble view for outbound messages.
    @objc public static var apptentiveMessageBubbleOutbound = UIColor(red: 0, green: 0.42, blue: 1, alpha: 1)

    /// The color to use for message labels for the inbound message body.
    @objc public static var apptentiveMessageLabelInbound = white

    /// The color to use for message labels for the outbound message body.
    @objc public static var apptentiveMessageLabelOutbound = white

    /// The color to use for labels in a non-error state.
    @objc public static var apptentiveQuestionLabel = apptentiveLabel

    /// The color to use for instruction labels.
    @objc public static var apptentiveInstructionsLabel = apptentiveSecondaryLabel

    /// The color to use for choice labels.
    @objc public static var apptentiveChoiceLabel = apptentiveLabel

    /// The color to use for UI elements to indicate an error state.
    @objc public static var apptentiveError: UIColor = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1)

        default:
            return UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1)
        }
    }

    /// The color to use for labels of primary prominance.
    internal static var apptentiveLabel = label

    /// The tint/accent color to use for buttons and similar controls in Apptentive interaction UI.
    @objc public static var apptentiveTint: UIColor = {
        if #available(iOS 15.0, *) {
            return .tintColor
        } else {
            return .systemBlue
        }
    }()

    /// The color to use for labels of secondary prominence.
    @objc public static var apptentiveSecondaryLabel = secondaryLabel

    /// The border color to use for the segmented control for range surveys.
    @objc public static var apptentiveRangeControlBorder = clear

    /// The color to use for the survey introduction text.
    @objc public static var apptentiveSurveyIntroduction = apptentiveLabel

    /// The color to use for the borders of text fields and text views.
    @objc public static var apptentiveTextInputBorder = lightGray

    /// The color to use for text fields and text views.
    @objc public static var apptentiveTextInputBackground = systemBackground

    /// The color to use for text within text fields and text views.
    @objc public static var apptentiveTextInput = label

    /// The color to use for the placeholder text within text fields and text views.
    @objc public static var apptentiveTextInputPlaceholder = placeholderText

    /// The color used for min and max labels for the range survey.
    @objc public static var apptentiveMinMaxLabel: UIColor = .apptentiveSecondaryLabel

    /// The color used for the background of the entire survey.
    @objc public static var apptentiveGroupedBackground = systemGroupedBackground

    /// The color used for the cell where the survey question is located.
    @objc public static var apptentiveSecondaryGroupedBackground = secondarySystemGroupedBackground

    /// The color to use for separators in e.g. table views.
    @objc public static var apptentiveSeparator = separator

    /// The color to use for images in a selected state for surveys.
    @objc public static var apptentiveImageSelected = apptentiveTint

    /// The color to use for images in a non-selected state for surveys.
    @objc public static var apptentiveImageNotSelected = apptentiveTint

    /// The background color to use for the submit button on surveys.
    @objc public static var apptentiveSubmitButton = apptentiveTint

    /// The background color to use for the footer which contains the terms and conditions for branched surveys.
    @objc public static var apptentiveBranchedSurveyFooter = tertiarySystemBackground

    /// The color to use for the survey footer label (Thank You text).
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveSubmitStatusLabel'.")
    public static var apptentiveSubmitLabel: UIColor {
        get {
            return .apptentiveSubmitStatusLabel
        }
        set {
            .apptentiveSubmitStatusLabel = newValue
        }
    }

    /// The color to use for the survey footer label (Thank You text).
    @objc public static var apptentiveSubmitStatusLabel = apptentiveLabel

    /// The color to use for the terms of service label.
    @objc public static var apptentiveTermsOfServiceLabel = apptentiveTint

    /// The color to use for the submit button text color.
    @objc public static var apptentiveSubmitButtonTitle = white

    /// The color to use for submit button border.
    @objc public static var apptentiveSubmitButtonBorder = clear

    /// The color to use for the space between questions.
    @objc public static var apptentiveQuestionSeparator = clear

    /// The color to use for the unselected segments for branched surveys.
    public static var apptentiveUnselectedSurveyIndicatorSegment = gray

    /// The color to use for the selected segments for branched surveys.
    public static var apptentiveSelectedSurveyIndicatorSegment = apptentiveTint

    /// The color to use for the background of Message Center.
    @objc public static var apptentiveMessageCenterBackground = systemBackground

    /// The color to use for the button that deletes the attachment from the draft message.
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveAttachmentRemoveButton'.")
    @objc public static var apptentiveMessageCenterAttachmentDeleteButton: UIColor {
        get {
            .apptentiveAttachmentRemoveButton
        }
        set {
            .apptentiveAttachmentRemoveButton = newValue
        }
    }

    /// The color to use for the button that deletes the attachment from the draft message.
    @objc public static var apptentiveAttachmentRemoveButton = UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1)

        default:
            return UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1)
        }
    }

    /// The color to use for the compose box for Message Center.
    @objc public static var apptentiveMessageCenterComposeBoxBackground = systemBackground

    /// The color to use for the compose box separator.
    @objc public static var apptentiveMessageCenterComposeBoxSeparator = separator

    /// The color to use for text input borders when selected.
    @objc public static var apptentiveTextInputBorderSelected = apptentiveTextInputBorder

    /// The text color used for the disclaimer text.
    @objc public static var apptentiveDisclaimerLabel = lightGray
}

extension UIFont {

    /// The font to use for placeholder for text inputs in message center.
    @objc public static var apptentiveMessageCenterTextInputPlaceholder = preferredFont(forTextStyle: .body)

    /// The font to use for text inputs in message menter.
    @objc public static var apptentiveMessageCenterTextInput = preferredFont(forTextStyle: .body)

    /// The font to use for placeholder text for text inputs in surveys.
    @objc public static var apptentiveTextInputPlaceholder = preferredFont(forTextStyle: .body)

    /// The font to use for the greeting title for message center.
    @objc public static var apptentiveMessageCenterStatus = preferredFont(forTextStyle: .footnote)

    /// The font to use for the greeting title for message center.
    @objc public static var apptentiveMessageCenterGreetingTitle = preferredFont(forTextStyle: .headline)

    /// The font to use for the greeting body for message center.
    @objc public static var apptentiveMessageCenterGreetingBody = preferredFont(forTextStyle: .body)

    /// The font to use for attachment placeholder file extension labels.
    @objc public static var apptentiveMessageCenterAttachmentLabel = preferredFont(forTextStyle: .caption1)

    /// The font used for all survey question labels.
    @objc public static var apptentiveQuestionLabel = preferredFont(forTextStyle: .headline)

    /// The font used for the terms of service.
    @objc public static var apptentiveTermsOfServiceLabel = preferredFont(forTextStyle: .footnote)

    /// The font used for all survey answer choice labels.
    @objc public static var apptentiveChoiceLabel = preferredFont(forTextStyle: .body)

    /// The font used for the message body in message center.
    @objc public static var apptentiveMessageLabel = preferredFont(forTextStyle: .body)

    /// The font used for the min and max labels for the range survey.
    @objc public static var apptentiveMinMaxLabel = preferredFont(forTextStyle: .footnote)

    /// The font used for the sender label in message center.
    @objc public static var apptentiveSenderLabel = preferredFont(forTextStyle: .caption2)

    /// The font used for the message date label in message center.
    @objc public static var apptentiveMessageDateLabel = preferredFont(forTextStyle: .caption2)

    /// The font used for the instructions label for surveys.
    @objc public static var apptentiveInstructionsLabel = preferredFont(forTextStyle: .footnote)

    /// The font used for the survey introduction label.
    @objc public static var apptentiveSurveyIntroductionLabel = preferredFont(forTextStyle: .subheadline)

    /// The font used for the survey footer label (Thank You text).
    @available(*, deprecated, message: "This property has been renamed to 'apptentiveSubmitStatusLabel'.")
    public static var apptentiveSubmitLabel: UIFont {
        get {
            .apptentiveSubmitStatusLabel
        }
        set {
            .apptentiveSubmitStatusLabel = newValue
        }
    }

    /// The font used for the survey footer label (Thank You text).
    @objc public static var apptentiveSubmitStatusLabel = preferredFont(forTextStyle: .headline)

    /// The font used for the disclaimer text.
    @objc public static var apptentiveDisclaimerLabel = preferredFont(forTextStyle: .callout)

    /// The font used for the submit button at the end of surveys.
    @objc public static var apptentiveSubmitButtonTitle = preferredFont(forTextStyle: .headline)

    /// The font used for the multi- and single-line text inputs in surveys.
    @objc public static var apptentiveTextInput = preferredFont(forTextStyle: .body)

    /// Repairs the scalability of ``UIFont.apptentiveTextInput`` for `UITextView` and `UITextField` use.
    internal func apptentiveRepairedFont() -> UIFont {
        guard let textStyleString = self.fontDescriptor.object(forKey: UIFontDescriptor.AttributeName.textStyle) as? String else {
            ApptentiveLogger.default.warning("Font \(self.debugDescription) has a missing or invalid textStyle and will not work with Dynamic Type.")
            return self
        }

        return UIFontMetrics(forTextStyle: UIFont.TextStyle(rawValue: textStyleString)).scaledFont(for: self)
    }

    func createUIFontMetricsForHTML() -> UIFont {
        let fontDescriptor = self.fontDescriptor
        if let textStyle = fontDescriptor.fontAttributes[.textStyle] as? UIFont.TextStyle {
            return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: self)
        }
        return self
    }
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
    /// The width of the layer border for Apptentive buttons for surveys.
    public static var apptentiveButtonBorderWidth: CGFloat = 2

    public static var apptentiveThumbnailScale: CGFloat = UIScreen.main.scale
}

extension CGSize {
    public static var apptentiveThumbnail = CGSize(width: 44, height: 44)
}
