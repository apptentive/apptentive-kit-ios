//
//  Apptentive+Theme.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/9/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

extension Apptentive {
    /// Overrides the system font in Apptentive interactions using the font with the specified name.
    @objc public static var fontName: String? {
        didSet {
            if let fontName = Self.fontName,
                let bodyFont = UIFont(name: fontName, size: 17.0),
                let footnoteFont = UIFont(name: fontName, size: 13.0),
                let caption1Font = UIFont(name: fontName, size: 12.0),
                let caption2Font = UIFont(name: fontName, size: 11.0),
                let subheadlineFont = UIFont(name: fontName, size: 15.0),
                let calloutFont = UIFont(name: fontName, size: 16.0)
            {
                let boldVariantDescriptor = bodyFont.fontDescriptor.withSymbolicTraits([.traitBold]) ?? bodyFont.fontDescriptor
                let headlineFont = UIFont(descriptor: boldVariantDescriptor, size: bodyFont.pointSize)

                UIFont.apptentiveMessageCenterTextInputPlaceholder = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
                UIFont.apptentiveMessageCenterTextInput = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
                UIFont.apptentiveTextInputPlaceholder = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
                UIFont.apptentiveMessageCenterStatus = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: footnoteFont)
                UIFont.apptentiveMessageCenterGreetingTitle = UIFontMetrics(forTextStyle: .headline).scaledFont(for: headlineFont)
                UIFont.apptentiveMessageCenterGreetingBody = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
                UIFont.apptentiveMessageCenterAttachmentLabel = UIFontMetrics(forTextStyle: .caption1).scaledFont(for: caption1Font)
                UIFont.apptentiveQuestionLabel = UIFontMetrics(forTextStyle: .headline).scaledFont(for: headlineFont)
                UIFont.apptentiveTermsOfServiceLabel = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: footnoteFont)
                UIFont.apptentiveChoiceLabel = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
                UIFont.apptentiveMessageLabel = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
                UIFont.apptentiveMinMaxLabel = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: footnoteFont)
                UIFont.apptentiveSenderLabel = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: caption2Font)
                UIFont.apptentiveMessageDateLabel = UIFontMetrics(forTextStyle: .caption2).scaledFont(for: caption2Font)
                UIFont.apptentiveInstructionsLabel = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: footnoteFont)
                UIFont.apptentiveSurveyIntroductionLabel = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: subheadlineFont)
                UIFont.apptentiveSubmitStatusLabel = UIFontMetrics(forTextStyle: .headline).scaledFont(for: headlineFont)
                UIFont.apptentiveDisclaimerLabel = UIFontMetrics(forTextStyle: .callout).scaledFont(for: calloutFont)
                UIFont.apptentiveSubmitButtonTitle = UIFontMetrics(forTextStyle: .headline).scaledFont(for: headlineFont)
                UIFont.apptentiveTextInput = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)

                DialogView.appearance().titleFont = UIFontMetrics(forTextStyle: .headline).scaledFont(for: headlineFont)
                DialogView.appearance().messageFont = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: footnoteFont)
                DialogButton.appearance().titleFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: bodyFont)
            } else {
                UIFont.apptentiveMessageCenterTextInputPlaceholder = .preferredFont(forTextStyle: .body)
                UIFont.apptentiveMessageCenterTextInput = .preferredFont(forTextStyle: .body)
                UIFont.apptentiveTextInputPlaceholder = .preferredFont(forTextStyle: .body)
                UIFont.apptentiveMessageCenterStatus = .preferredFont(forTextStyle: .footnote)
                UIFont.apptentiveMessageCenterGreetingTitle = .preferredFont(forTextStyle: .headline)
                UIFont.apptentiveMessageCenterGreetingBody = .preferredFont(forTextStyle: .body)
                UIFont.apptentiveMessageCenterAttachmentLabel = .preferredFont(forTextStyle: .caption1)
                UIFont.apptentiveQuestionLabel = .preferredFont(forTextStyle: .headline)
                UIFont.apptentiveTermsOfServiceLabel = .preferredFont(forTextStyle: .footnote)
                UIFont.apptentiveChoiceLabel = .preferredFont(forTextStyle: .body)
                UIFont.apptentiveMessageLabel = .preferredFont(forTextStyle: .body)
                UIFont.apptentiveMinMaxLabel = .preferredFont(forTextStyle: .footnote)
                UIFont.apptentiveSenderLabel = .preferredFont(forTextStyle: .caption2)
                UIFont.apptentiveMessageDateLabel = .preferredFont(forTextStyle: .caption2)
                UIFont.apptentiveInstructionsLabel = .preferredFont(forTextStyle: .footnote)
                UIFont.apptentiveSurveyIntroductionLabel = .preferredFont(forTextStyle: .subheadline)
                UIFont.apptentiveSubmitStatusLabel = .preferredFont(forTextStyle: .headline)
                UIFont.apptentiveDisclaimerLabel = .preferredFont(forTextStyle: .callout)
                UIFont.apptentiveSubmitButtonTitle = .preferredFont(forTextStyle: .headline)
                UIFont.apptentiveTextInput = .preferredFont(forTextStyle: .body)

                DialogView.appearance().titleFont = .preferredFont(forTextStyle: .headline)
                DialogView.appearance().messageFont = .preferredFont(forTextStyle: .footnote)
                DialogButton.appearance().titleFont = .preferredFont(forTextStyle: .body)
            }
        }
    }

    /// This method will set colors and non-resizeable images from any asset catalog included in the app's main bundle.
    static func applyCustomerTheme(from bundle: Bundle = .main) {
        UIColor(named: "Apptentive/Survey/IntroductionText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveSurveyIntroduction = $0 }
        UIColor(named: "Apptentive/Survey/QuestionText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveQuestionLabel = $0 }
        UIColor(named: "Apptentive/Survey/InstructionsText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveInstructionsLabel = $0 }
        UIColor(named: "Apptentive/Error", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveError = $0 }
        UIColor(named: "Apptentive/Survey/ChoiceImageSelected", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveImageSelected = $0 }
        UIColor(named: "Apptentive/Survey/ChoiceImage", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveImageNotSelected = $0 }
        UIColor(named: "Apptentive/Survey/ChoiceText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveChoiceLabel = $0 }
        UIColor(named: "Apptentive/TextInputBorder", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveTextInputBorder = $0 }
        UIColor(named: "Apptentive/TextInputBorderSelected", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveTextInputBorderSelected = $0 }
        UIColor(named: "Apptentive/TextInputBackground", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveTextInputBackground = $0 }
        UIColor(named: "Apptentive/TextInput", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveTextInput = $0 }
        UIColor(named: "Apptentive/TextInputPlaceholder", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveTextInputPlaceholder = $0 }
        UIColor(named: "Apptentive/Survey/ProgressSegmentCurrent", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveSelectedSurveyIndicatorSegment = $0 }
        UIColor(named: "Apptentive/Survey/ProgressSegment", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveUnselectedSurveyIndicatorSegment = $0 }
        UIColor(named: "Apptentive/Survey/RangeControlBorder", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveRangeControlBorder = $0 }
        UIColor(named: "Apptentive/GroupedBackground", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveGroupedBackground = $0 }
        UIColor(named: "Apptentive/SecondaryGroupedBackground", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveSecondaryGroupedBackground = $0 }
        UIColor(named: "Apptentive/Separator", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveSeparator = $0 }
        UIColor(named: "Apptentive/Survey/SubmitButton", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveSubmitButton = $0 }
        UIColor(named: "Apptentive/Survey/ProgressFooter", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveBranchedSurveyFooter = $0 }
        UIColor(named: "Apptentive/Survey/DisclaimerText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveDisclaimerLabel = $0 }
        UIColor(named: "Apptentive/Survey/TermsOfServiceText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveTermsOfServiceLabel = $0 }
        UIColor(named: "Apptentive/MessageCenter/GreetingTitleText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterGreetingTitle = $0 }
        UIColor(named: "Apptentive/MessageCenter/GreetingBodyText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterGreetingBody = $0 }
        UIColor(named: "Apptentive/MessageCenter/MessageBubbleInbound", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageBubbleInbound = $0 }
        UIColor(named: "Apptentive/MessageCenter/MessageBubbleOutbound", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageBubbleOutbound = $0 }
        UIColor(named: "Apptentive/MessageCenter/MessageTextOutbound", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageLabelOutbound = $0 }
        UIColor(named: "Apptentive/MessageCenter/MessageTextInbound", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageLabelInbound = $0 }
        UIColor(named: "Apptentive/MessageCenter/TextInputBorder", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterTextInputBorder = $0 }
        UIColor(named: "Apptentive/MessageCenter/TextInputBackground", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterTextInputBackground = $0 }
        UIColor(named: "Apptentive/MessageCenter/TextInput", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterTextInput = $0 }
        UIColor(named: "Apptentive/MessageCenter/TextInputPlaceholder", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterTextInputPlaceholder = $0 }
        UIColor(named: "Apptentive/MessageCenter/Background", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterBackground = $0 }
        UIColor(named: "Apptentive/MessageCenter/ComposeBoxBackground", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterComposeBoxBackground = $0 }
        UIColor(named: "Apptentive/MessageCenter/StatusText", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveMessageCenterStatus = $0 }
        UIColor(named: "Apptentive/MessageCenter/AttachmentRemoveButton", in: bundle, compatibleWith: nil).flatMap { UIColor.apptentiveAttachmentRemoveButton = $0 }

        UIColor(named: "Apptentive/Dialog/Background", in: bundle, compatibleWith: nil).flatMap {
            DialogView.appearance().backgroundColor = $0
            UIVisualEffectView.appearance(whenContainedInInstancesOf: [DialogView.self]).effect = .none
        }
        UIColor(named: "Apptentive/Dialog/TitleText", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance().titleTextColor = $0 }
        UIColor(named: "Apptentive/Dialog/MessageText", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance().messageTextColor = $0 }
        UIColor(named: "Apptentive/Dialog/Separator", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance().separatorColor = $0 }

        UIColor(named: "Apptentive/TextModal/Background", in: bundle, compatibleWith: nil).flatMap {
            DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).backgroundColor = $0
            UIVisualEffectView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).effect = .none
        }
        UIColor(named: "Apptentive/TextModal/TitleText", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).titleTextColor = $0 }
        UIColor(named: "Apptentive/TextModal/MessageText", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).messageTextColor = $0 }
        UIColor(named: "Apptentive/TextModal/Separator", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).separatorColor = $0 }

        UIColor(named: "Apptentive/EnjoymentDialog/Background", in: bundle, compatibleWith: nil).flatMap {
            DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).backgroundColor = $0
            UIVisualEffectView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).effect = .none
        }
        UIColor(named: "Apptentive/EnjoymentDialog/TitleText", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).titleTextColor = $0 }
        UIColor(named: "Apptentive/EnjoymentDialog/MessageText", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).messageTextColor = $0 }
        UIColor(named: "Apptentive/EnjoymentDialog/Separator", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).separatorColor = $0 }

        UIImage(named: "Apptentive/Survey/RadioButton", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveRadioButton = $0 }
        UIImage(named: "Apptentive/Survey/Checkbox", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveCheckbox = $0 }
        UIImage(named: "Apptentive/Survey/RadioButtonSelected", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveRadioButtonSelected = $0 }
        UIImage(named: "Apptentive/Survey/CheckboxSelected", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveCheckboxSelected = $0 }
        UIImage(named: "Apptentive/MessageCenter/AttachButton", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveMessageAttachmentButton = $0 }
        UIImage(named: "Apptentive/MessageCenter/SendButton", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveMessageSendButton = $0 }
        UIImage(named: "Apptentive/MessageCenter/AttachmentRemoveButton", in: bundle, compatibleWith: nil).flatMap { UIImage.apptentiveAttachmentRemoveButton = $0 }
        UIImage(named: "Apptentive/Dialog/Header", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance().headerImage = $0 }
        UIImage(named: "Apptentive/TextModal/Header", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).headerImage = $0 }
        UIImage(named: "Apptentive/EnjoymentDialog/Header", in: bundle, compatibleWith: nil).flatMap { DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).headerImage = $0 }
    }

    /// This method will apply the default cross-platform Apptentive look for Apptentive UI.
    static func applyApptentiveTheme() {
        let bundle = Bundle.apptentive
        guard let barTintColor = UIColor(named: "barTint", in: bundle, compatibleWith: nil),
            let barForegroundColor = UIColor(named: "barForeground", in: bundle, compatibleWith: nil),
            let surveyGreeting = UIColor(named: "surveyGreetingText", in: bundle, compatibleWith: nil),
            let question = UIColor(named: "question", in: bundle, compatibleWith: nil),
            let instructionsLabelColor = UIColor(named: "instructionsLabel", in: bundle, compatibleWith: nil),
            let error = UIColor(named: "apptentiveError", in: bundle, compatibleWith: nil),
            let surveyImageChoice = UIColor(named: "surveyImageChoice", in: bundle, compatibleWith: nil),
            let imageNotSelectedColor = UIColor(named: "imageNotSelected", in: bundle, compatibleWith: nil),
            let choiceLabelColor = UIColor(named: "choiceLabel", in: bundle, compatibleWith: nil),
            let textInputBorderColor = UIColor(named: "textInputBorder", in: bundle, compatibleWith: nil),
            let textInputBorderSelected = UIColor(named: "textInputBorderSelected", in: bundle, compatibleWith: nil),
            let textInputBackgroundColor = UIColor(named: "textInputBackground", in: bundle, compatibleWith: nil),
            let textInputColor = UIColor(named: "textInput", in: bundle, compatibleWith: nil),
            let textInputPlaceholder = UIColor(named: "textInputPlaceholder", in: bundle, compatibleWith: nil),
            let buttonTintColor = UIColor(named: "buttonTint", in: bundle, compatibleWith: nil),
            let unselectedSurveyIndicatorColor = UIColor(named: "unselectedSurveyIndicator", in: bundle, compatibleWith: nil),
            let apptentiveRangeControlBorder = UIColor(named: "apptentiveRangeControlBorder", in: bundle, compatibleWith: nil),
            let apptentiveGroupPrimaryColor = UIColor(named: "apptentiveGroupPrimary", in: bundle, compatibleWith: nil),
            let apptentiveGroupSecondaryColor = UIColor(named: "apptentiveGroupSecondary", in: bundle, compatibleWith: nil),
            let termsOfServiceColor = UIColor(named: "termsOfService", in: bundle, compatibleWith: nil),
            let disclaimerColor = UIColor(named: "disclaimer", in: bundle, compatibleWith: nil),
            let messageBubbleInboundColor = UIColor(named: "messageBubbleInbound", in: bundle, compatibleWith: nil),
            let messageLabelInboundColor = UIColor(named: "messageLabelInbound", in: bundle, compatibleWith: nil),
            let messageBubbleOutboundColor = UIColor(named: "messageBubbleOutbound", in: bundle, compatibleWith: nil),
            let messageTextInputBorderColor = UIColor(named: "messageTextInputBorder", in: bundle, compatibleWith: nil),
            let dialogSeparator = UIColor(named: "dialogSeparator", in: bundle, compatibleWith: nil),
            let dialogText = UIColor(named: "dialogText", in: bundle, compatibleWith: nil),
            let dialogButtonText = UIColor(named: "dialogButtonText", in: bundle, compatibleWith: nil),
            let attachmentDeleteButton = UIColor(named: "attachmentDeleteButton", in: bundle, compatibleWith: nil)
        else {
            apptentiveCriticalError("Unable to locate color asset(s).")
            return
        }

        let barTitleTextAttributes = [NSAttributedString.Key.foregroundColor: barForegroundColor, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title2)]

        ApptentiveNavigationController.preferredStatusBarStyle = .lightContent

        UIModalPresentationStyle.apptentive = .fullScreen

        let navigationBarAppearanceProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
        navigationBarAppearanceProxy.titleTextAttributes = barTitleTextAttributes

        let toolBarAppearanceProxy = UIToolbar.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])

        let barAppearance = UIBarAppearance()
        barAppearance.configureWithOpaqueBackground()
        barAppearance.backgroundColor = barTintColor

        let navigationBarAppearance = UINavigationBarAppearance(barAppearance: barAppearance)
        navigationBarAppearance.titleTextAttributes = barTitleTextAttributes
        navigationBarAppearanceProxy.standardAppearance = navigationBarAppearance
        navigationBarAppearanceProxy.scrollEdgeAppearance = navigationBarAppearance

        toolBarAppearanceProxy.standardAppearance = UIToolbarAppearance(barAppearance: barAppearance)
        if #available(iOS 15.0, *) {
            toolBarAppearanceProxy.scrollEdgeAppearance = toolBarAppearanceProxy.standardAppearance
        }

        UIToolbar.apptentiveMode = .alwaysShown

        let buttonTitleTextAttributes = [NSAttributedString.Key.foregroundColor: barForegroundColor, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]

        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
        barButtonItemAppearance.setTitleTextAttributes(buttonTitleTextAttributes, for: .normal)
        barButtonItemAppearance.tintColor = barForegroundColor

        let backgroundColor: UIColor = {
            return .systemBackground

        }()
        let tableViewAppearance = UITableView.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])

        tableViewAppearance.backgroundColor = backgroundColor
        tableViewAppearance.separatorColor = backgroundColor

        // Apptentive UIKit extensions overrides
        UITableView.Style.apptentive = .grouped

        UIColor.apptentiveSurveyIntroduction = surveyGreeting
        UIColor.apptentiveQuestionLabel = question
        UIColor.apptentiveInstructionsLabel = instructionsLabelColor
        UIColor.apptentiveError = error
        UIColor.apptentiveImageSelected = surveyImageChoice
        UIColor.apptentiveImageNotSelected = imageNotSelectedColor
        UIColor.apptentiveChoiceLabel = choiceLabelColor
        UIColor.apptentiveTextInputBorder = textInputBorderColor
        UIColor.apptentiveTextInputBorderSelected = textInputBorderSelected
        UIColor.apptentiveTextInputBackground = textInputBackgroundColor
        UIColor.apptentiveTextInput = textInputColor
        UIColor.apptentiveTextInputPlaceholder = textInputPlaceholder
        UIColor.apptentiveSelectedSurveyIndicatorSegment = buttonTintColor
        UIColor.apptentiveUnselectedSurveyIndicatorSegment = unselectedSurveyIndicatorColor
        UIColor.apptentiveRangeControlBorder = apptentiveRangeControlBorder
        UIColor.apptentiveGroupedBackground = apptentiveGroupPrimaryColor
        UIColor.apptentiveSecondaryGroupedBackground = apptentiveGroupSecondaryColor
        UIColor.apptentiveSeparator = apptentiveGroupPrimaryColor
        UIColor.apptentiveSubmitButton = buttonTintColor
        UIColor.apptentiveBranchedSurveyFooter = barTintColor
        UIColor.apptentiveDisclaimerLabel = disclaimerColor
        UIColor.apptentiveTermsOfServiceLabel = termsOfServiceColor

        UIColor.apptentiveMessageCenterGreetingTitle = surveyGreeting
        UIColor.apptentiveMessageCenterGreetingBody = question
        UIColor.apptentiveMessageBubbleInbound = messageBubbleInboundColor
        UIColor.apptentiveMessageBubbleOutbound = messageBubbleOutboundColor
        UIColor.apptentiveMessageLabelOutbound = termsOfServiceColor
        UIColor.apptentiveMessageLabelInbound = messageLabelInboundColor
        UIColor.apptentiveMessageCenterTextInputBorder = messageTextInputBorderColor
        UIColor.apptentiveMessageCenterTextInputBackground = textInputBackgroundColor
        UIColor.apptentiveMessageCenterTextInput = textInputColor
        UIColor.apptentiveMessageCenterTextInputPlaceholder = textInputPlaceholder
        UIColor.apptentiveMessageCenterBackground = apptentiveGroupPrimaryColor
        UIColor.apptentiveMessageCenterComposeBoxBackground = apptentiveGroupPrimaryColor
        UIColor.apptentiveMessageCenterStatus = textInputColor
        UIColor.apptentiveAttachmentRemoveButton = attachmentDeleteButton

        UIFont.apptentiveQuestionLabel = .preferredFont(forTextStyle: .body)
        UIFont.apptentiveChoiceLabel = .preferredFont(forTextStyle: .body)
        UIFont.apptentiveTextInput = .preferredFont(forTextStyle: .body)

        DialogView.appearance().titleTextColor = dialogText
        DialogView.appearance().separatorColor = dialogSeparator
        DialogButton.appearance().tintColor = dialogButtonText
        DialogView.appearance().backgroundColor = apptentiveGroupPrimaryColor

        UIBarButtonItem.apptentiveClose = {
            let systemClose = UIBarButtonItem(barButtonSystemItem: .close, target: nil, action: nil)
            let closeImage = UIImage(systemName: "xmark")
            let result = UIBarButtonItem(image: closeImage, landscapeImagePhone: closeImage, style: .plain, target: nil, action: nil)

            result.accessibilityLabel = systemClose.accessibilityLabel
            result.accessibilityHint = systemClose.accessibilityHint

            return result
        }()

        UIButton.apptentiveStyle = .radius(8.0)
        UIButton.apptentiveClose?.tintColor = .white
    }
}
