//
//  ThemeTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 4/2/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor
final class ThemeTests {
    @Test func testTheming() throws {
        withNoTheme()
        try withApptentiveTheme()
        try withCustomerTheme()
    }

    @MainActor func withCustomerTheme() throws {
        let bundle = Bundle(for: BundleFinder.self)
        Apptentive.applyCustomerTheme(from: bundle)

        guard let errorColor = UIColor(named: "Apptentive/Error", in: bundle, compatibleWith: nil),
            let groupedBackgroundColor = UIColor(named: "Apptentive/GroupedBackground", in: bundle, compatibleWith: nil),
            let attachmentRemoveButtonColor = UIColor(named: "Apptentive/MessageCenter/AttachmentRemoveButton", in: bundle, compatibleWith: nil),
            let messageCenterBackgroundColor = UIColor(named: "Apptentive/MessageCenter/Background", in: bundle, compatibleWith: nil),
            let messageCenterComposeBoxBackgroundColor = UIColor(named: "Apptentive/MessageCenter/ComposeBoxBackground", in: bundle, compatibleWith: nil),
            let messageCenterGreetingBodyColor = UIColor(named: "Apptentive/MessageCenter/GreetingBodyText", in: bundle, compatibleWith: nil),
            let messageCenterGreetingTitleColor = UIColor(named: "Apptentive/MessageCenter/GreetingTitleText", in: bundle, compatibleWith: nil),
            let messageBubbleInboundColor = UIColor(named: "Apptentive/MessageCenter/MessageBubbleInbound", in: bundle, compatibleWith: nil),
            let messageBubbleOutboundColor = UIColor(named: "Apptentive/MessageCenter/MessageBubbleOutbound", in: bundle, compatibleWith: nil),
            let messageLabelInboundColor = UIColor(named: "Apptentive/MessageCenter/MessageTextInbound", in: bundle, compatibleWith: nil),
            let messageLabelOutboundColor = UIColor(named: "Apptentive/MessageCenter/MessageTextOutbound", in: bundle, compatibleWith: nil),
            let messageCenterStatusColor = UIColor(named: "Apptentive/MessageCenter/StatusText", in: bundle, compatibleWith: nil),
            let messageCenterTextInputColor = UIColor(named: "Apptentive/MessageCenter/TextInput", in: bundle, compatibleWith: nil),
            let messageCenterTextInputBackgroundColor = UIColor(named: "Apptentive/MessageCenter/TextInputBackground", in: bundle, compatibleWith: nil),
            let messageCenterTextInputBorderColor = UIColor(named: "Apptentive/MessageCenter/TextInputBorder", in: bundle, compatibleWith: nil),
            let messageCenterTextInputPlaceholderColor = UIColor(named: "Apptentive/MessageCenter/TextInputPlaceholder", in: bundle, compatibleWith: nil),
            let secondaryGroupedBackgroundColor = UIColor(named: "Apptentive/SecondaryGroupedBackground", in: bundle, compatibleWith: nil),
            let separatorColor = UIColor(named: "Apptentive/Separator", in: bundle, compatibleWith: nil),
            let imageNotSelectedColor = UIColor(named: "Apptentive/Survey/ChoiceImage", in: bundle, compatibleWith: nil),
            let imageSelectedColor = UIColor(named: "Apptentive/Survey/ChoiceImageSelected", in: bundle, compatibleWith: nil),
            let choiceLabelColor = UIColor(named: "Apptentive/Survey/ChoiceText", in: bundle, compatibleWith: nil),
            let disclaimerLabelColor = UIColor(named: "Apptentive/Survey/DisclaimerText", in: bundle, compatibleWith: nil),
            let instructionsLabelColor = UIColor(named: "Apptentive/Survey/InstructionsText", in: bundle, compatibleWith: nil),
            let surveyIntroductionColor = UIColor(named: "Apptentive/Survey/IntroductionText", in: bundle, compatibleWith: nil),
            let branchedSurveyFooterColor = UIColor(named: "Apptentive/Survey/ProgressFooter", in: bundle, compatibleWith: nil),
            let surveyProgressSegment = UIColor(named: "Apptentive/Survey/ProgressSegment", in: bundle, compatibleWith: nil),
            let surveyProgressSegmentCurrent = UIColor(named: "Apptentive/Survey/ProgressSegmentCurrent", in: bundle, compatibleWith: nil),
            let questionLabelColor = UIColor(named: "Apptentive/Survey/QuestionText", in: bundle, compatibleWith: nil),
            let rangeControlBorderColor = UIColor(named: "Apptentive/Survey/RangeControlBorder", in: bundle, compatibleWith: nil),
            let submitButtonColor = UIColor(named: "Apptentive/Survey/SubmitButton", in: bundle, compatibleWith: nil),
            let termsOfServiceLabelColor = UIColor(named: "Apptentive/Survey/TermsOfServiceText", in: bundle, compatibleWith: nil),
            let textInputColor = UIColor(named: "Apptentive/TextInput", in: bundle, compatibleWith: nil),
            let textInputBackgroundColor = UIColor(named: "Apptentive/TextInputBackground", in: bundle, compatibleWith: nil),
            let textInputBorderColor = UIColor(named: "Apptentive/TextInputBorder", in: bundle, compatibleWith: nil),
            let textInputBorderSelectedColor = UIColor(named: "Apptentive/TextInputBorderSelected", in: bundle, compatibleWith: nil),
            let textInputPlaceholderColor = UIColor(named: "Apptentive/TextInputPlaceholder", in: bundle, compatibleWith: nil),
            let dialogBackgroundColor = UIColor(named: "Apptentive/Dialog/Background", in: bundle, compatibleWith: nil),
            let dialogTitleTextColor = UIColor(named: "Apptentive/Dialog/TitleText", in: bundle, compatibleWith: nil),
            let dialogMessageTextColor = UIColor(named: "Apptentive/Dialog/MessageText", in: bundle, compatibleWith: nil),
            let dialogSeparatorColor = UIColor(named: "Apptentive/Dialog/Separator", in: bundle, compatibleWith: nil),
            let textModalBackgroundColor = UIColor(named: "Apptentive/TextModal/Background", in: bundle, compatibleWith: nil),
            let textModalTitleTextColor = UIColor(named: "Apptentive/TextModal/TitleText", in: bundle, compatibleWith: nil),
            let textModalMessageTextColor = UIColor(named: "Apptentive/TextModal/MessageText", in: bundle, compatibleWith: nil),
            let textModalSeparatorColor = UIColor(named: "Apptentive/TextModal/Separator", in: bundle, compatibleWith: nil),
            let enjoymentDialogBackgroundColor = UIColor(named: "Apptentive/EnjoymentDialog/Background", in: bundle, compatibleWith: nil),
            let enjoymentDialogTitleTextColor = UIColor(named: "Apptentive/EnjoymentDialog/TitleText", in: bundle, compatibleWith: nil),
            let enjoymentDialogMessageTextColor = UIColor(named: "Apptentive/EnjoymentDialog/MessageText", in: bundle, compatibleWith: nil),
            let enjoymentDialogSeparatorColor = UIColor(named: "Apptentive/EnjoymentDialog/Separator", in: bundle, compatibleWith: nil),
            let messageAttachmentButtonImage = UIImage(named: "Apptentive/MessageCenter/AttachButton", in: bundle, compatibleWith: nil),
            let attachmentRemoveButtonImage = UIImage(named: "Apptentive/MessageCenter/AttachmentRemoveButton", in: bundle, compatibleWith: nil),
            let messageSendButtonImage = UIImage(named: "Apptentive/MessageCenter/SendButton", in: bundle, compatibleWith: nil),
            let checkboxImage = UIImage(named: "Apptentive/Survey/Checkbox", in: bundle, compatibleWith: nil),
            let checkboxSelectedImage = UIImage(named: "Apptentive/Survey/CheckboxSelected", in: bundle, compatibleWith: nil),
            let radioButtonImage = UIImage(named: "Apptentive/Survey/RadioButton", in: bundle, compatibleWith: nil),
            let radioButtonSelectedImage = UIImage(named: "Apptentive/Survey/RadioButtonSelected", in: bundle, compatibleWith: nil),
            let dialogHeaderImage = UIImage(named: "Apptentive/Dialog/Header", in: bundle, compatibleWith: nil),
            let enjoymentDialogHeaderImage = UIImage(named: "Apptentive/EnjoymentDialog/Header", in: bundle, compatibleWith: nil),
            let textModalHeaderImage = UIImage(named: "Apptentive/TextModal/Header", in: bundle, compatibleWith: nil)
        else {
            throw TestError(reason: "Missing one or more required assets")
        }

        #expect(UIColor.apptentiveSurveyIntroduction == surveyIntroductionColor)
        #expect(UIColor.apptentiveQuestionLabel == questionLabelColor)
        #expect(UIColor.apptentiveInstructionsLabel == instructionsLabelColor)
        #expect(UIColor.apptentiveError == errorColor)
        #expect(UIColor.apptentiveImageSelected == imageSelectedColor)
        #expect(UIColor.apptentiveImageNotSelected == imageNotSelectedColor)
        #expect(UIColor.apptentiveChoiceLabel == choiceLabelColor)
        #expect(UIColor.apptentiveTextInputBorder == textInputBorderColor)
        #expect(UIColor.apptentiveTextInputBorderSelected == textInputBorderSelectedColor)
        #expect(UIColor.apptentiveTextInputBackground == textInputBackgroundColor)
        #expect(UIColor.apptentiveTextInput == textInputColor)
        #expect(UIColor.apptentiveTextInputPlaceholder == textInputPlaceholderColor)
        #expect(UIColor.apptentiveSelectedSurveyIndicatorSegment == surveyProgressSegmentCurrent)
        #expect(UIColor.apptentiveUnselectedSurveyIndicatorSegment == surveyProgressSegment)
        #expect(UIColor.apptentiveRangeControlBorder == rangeControlBorderColor)
        #expect(UIColor.apptentiveGroupedBackground == groupedBackgroundColor)
        #expect(UIColor.apptentiveSecondaryGroupedBackground == secondaryGroupedBackgroundColor)
        #expect(UIColor.apptentiveSeparator == separatorColor)
        #expect(UIColor.apptentiveSubmitButton == submitButtonColor)
        #expect(UIColor.apptentiveBranchedSurveyFooter == branchedSurveyFooterColor)
        #expect(UIColor.apptentiveDisclaimerLabel == disclaimerLabelColor)
        #expect(UIColor.apptentiveTermsOfServiceLabel == termsOfServiceLabelColor)
        #expect(UIColor.apptentiveMessageCenterGreetingTitle == messageCenterGreetingTitleColor)
        #expect(UIColor.apptentiveMessageCenterGreetingBody == messageCenterGreetingBodyColor)
        #expect(UIColor.apptentiveMessageBubbleInbound == messageBubbleInboundColor)
        #expect(UIColor.apptentiveMessageBubbleOutbound == messageBubbleOutboundColor)
        #expect(UIColor.apptentiveMessageLabelOutbound == messageLabelOutboundColor)
        #expect(UIColor.apptentiveMessageLabelInbound == messageLabelInboundColor)
        #expect(UIColor.apptentiveMessageCenterTextInputBorder == messageCenterTextInputBorderColor)
        #expect(UIColor.apptentiveMessageCenterTextInputBackground == messageCenterTextInputBackgroundColor)
        #expect(UIColor.apptentiveMessageCenterTextInput == messageCenterTextInputColor)
        #expect(UIColor.apptentiveMessageCenterTextInputPlaceholder == messageCenterTextInputPlaceholderColor)
        #expect(UIColor.apptentiveMessageCenterBackground == messageCenterBackgroundColor)
        #expect(UIColor.apptentiveMessageCenterComposeBoxBackground == messageCenterComposeBoxBackgroundColor)
        #expect(UIColor.apptentiveMessageCenterStatus == messageCenterStatusColor)
        #expect(UIColor.apptentiveAttachmentRemoveButton == attachmentRemoveButtonColor)
        #expect(UIColor.apptentiveSecondaryGroupedBackground == secondaryGroupedBackgroundColor)
        #expect(dialogBackgroundColor == DialogView.appearance().backgroundColor)
        #expect(dialogTitleTextColor == DialogView.appearance().titleTextColor)
        #expect(dialogMessageTextColor == DialogView.appearance().messageTextColor)
        #expect(dialogSeparatorColor == DialogView.appearance().separatorColor)
        #expect(enjoymentDialogBackgroundColor == DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).backgroundColor)
        #expect(enjoymentDialogTitleTextColor == DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).titleTextColor)
        #expect(enjoymentDialogMessageTextColor == DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).messageTextColor)
        #expect(enjoymentDialogSeparatorColor == DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).separatorColor)
        #expect(textModalBackgroundColor == DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).backgroundColor)
        #expect(textModalTitleTextColor == DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).titleTextColor)
        #expect(textModalMessageTextColor == DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).messageTextColor)
        #expect(textModalSeparatorColor == DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).separatorColor)

        #expect(UIVisualEffectView.appearance(whenContainedInInstancesOf: [DialogView.self]).effect == .none)
        #expect(UIVisualEffectView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).effect == .none)
        #expect(UIVisualEffectView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).effect == .none)

        #expect(UIImage.apptentiveRadioButton == radioButtonImage)
        #expect(UIImage.apptentiveCheckbox == checkboxImage)
        #expect(UIImage.apptentiveRadioButtonSelected == radioButtonSelectedImage)
        #expect(UIImage.apptentiveCheckboxSelected == checkboxSelectedImage)
        #expect(UIImage.apptentiveMessageAttachmentButton == messageAttachmentButtonImage)
        #expect(UIImage.apptentiveMessageSendButton == messageSendButtonImage)
        #expect(UIImage.apptentiveAttachmentRemoveButton == attachmentRemoveButtonImage)
        #expect(UIImage.apptentiveMessageAttachmentButton == messageAttachmentButtonImage)
        #expect(dialogHeaderImage == DialogView.appearance().headerImage)
        #expect(enjoymentDialogHeaderImage == DialogView.appearance(whenContainedInInstancesOf: [EnjoymentDialogViewController.self]).headerImage)
        #expect(textModalHeaderImage == DialogView.appearance(whenContainedInInstancesOf: [TextModalViewController.self]).headerImage)
    }

    @MainActor func withNoTheme() {
        #expect(ApptentiveNavigationController.preferredStatusBarStyle == .default)

        // Increases the header height for surveys.
        #expect(ApptentiveNavigationController.prefersLargeHeader == false)

        // Determines height of the separator between questions.
        #expect(UITableView.apptentiveQuestionSeparatorHeight == 0)

        // The table view style to use for Apptentive UI.
        #expect(UITableView.Style.apptentive == .insetGrouped)

        // The modal presentation style to use for Surveys and Message Center.
        #expect(UIModalPresentationStyle.apptentive == .pageSheet)

        // The style for call-to-action buttons in Apptentive UI.
        #expect(UIButton.apptentiveStyle == .pill)

        // MARK: Colors

        let lightTC = UITraitCollection(userInterfaceStyle: .light)
        let darkTC = UITraitCollection(userInterfaceStyle: .dark)

        // The color to use for the background in text inputs for message center.
        #expect(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: lightTC) == .white)
        #expect(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: darkTC) == .black)

        // The placeholder color to use for text inputs for message center.
        #expect(UIColor.apptentiveMessageCenterTextInputPlaceholder == .placeholderText)

        // The text color to use for all text inputs in message center.
        #expect(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: lightTC) == .label.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: darkTC) == .label.resolvedColor(with: darkTC))

        // The tint color for text inputs for surveys.
        #expect(UIColor.apptentivetextInputTint == .apptentiveTint)

        // The border color to use for the message text view.
        #expect(UIColor.apptentiveMessageCenterTextInputBorder == .lightGray)

        // The color to use for the attachment button for the compose view for message center.
        #expect(UIColor.apptentiveMessageCenterAttachmentButton == .apptentiveTint)

        // The color to use for the text view placeholder for the compose view for message center.
        #expect(UIColor.apptentiveMessageTextInputPlaceholder == .placeholderText)

        // The color to use for the status message in message center.
        #expect(UIColor.apptentiveMessageCenterStatus == .apptentiveSecondaryLabel)

        // The color to use for the greeting body on the greeting header view for message center.
        #expect(UIColor.apptentiveMessageCenterGreetingBody == .apptentiveSecondaryLabel)

        // The color to use for the greeting title on the greeting header view for message center.
        #expect(UIColor.apptentiveMessageCenterGreetingTitle == .apptentiveSecondaryLabel)

        // The color to use for the message bubble view for inbound messages.
        #expect(UIColor.apptentiveMessageBubbleInbound == .darkGray)

        // The color to use for the message bubble view for outbound messages.
        #expect(UIColor.apptentiveMessageBubbleOutbound == UIColor(red: 0, green: 0.42, blue: 1, alpha: 1))

        // The color to use for message labels for the inbound message body.
        #expect(UIColor.apptentiveMessageLabelInbound == .white)

        // The color to use for message labels for the outbound message body.
        #expect(UIColor.apptentiveMessageLabelOutbound == .white)

        // The color to use for labels in a non-error state.
        #expect(UIColor.apptentiveQuestionLabel == .apptentiveLabel)

        // The color to use for instruction labels.
        #expect(UIColor.apptentiveInstructionsLabel == .apptentiveSecondaryLabel)

        // The color to use for UI elements to indicate an error state.
        #expect(UIColor.apptentiveError.resolvedColor(with: lightTC) == UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1))
        #expect(UIColor.apptentiveError.resolvedColor(with: darkTC) == UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1))

        // The color to use for labels of primary prominance.
        #expect(UIColor.apptentiveLabel == .label)

        // The tint/accent color to use for buttons and similar controls in Apptentive interaction UI.
        if #available(iOS 15.0, *) {
            #expect(UIColor.apptentiveTint == .tintColor)
        } else {
            #expect(UIColor.apptentiveTint == .systemBlue)
        }

        // The color to use for labels of secondary prominence.
        #expect(UIColor.apptentiveSecondaryLabel == .secondaryLabel)

        // The border color to use for the segmented control for range surveys.
        #expect(UIColor.apptentiveRangeControlBorder == .clear)

        // The color to use for the survey introduction text.
        #expect(UIColor.apptentiveSurveyIntroduction == .apptentiveLabel)

        // The color to use for the borders of text fields and text views.
        #expect(UIColor.apptentiveTextInputBorder == .lightGray)

        // The color to use for text fields and text views.
        #expect(UIColor.apptentiveTextInputBackground.resolvedColor(with: lightTC) == .white)
        #expect(UIColor.apptentiveTextInputBackground.resolvedColor(with: darkTC) == .black)

        // The color to use for text within text fields and text views.
        #expect(UIColor.apptentiveTextInput.resolvedColor(with: lightTC) == .label.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveTextInput.resolvedColor(with: darkTC) == .label.resolvedColor(with: darkTC))

        // The color used for min and max labels for the range survey.
        #expect(UIColor.apptentiveMinMaxLabel == .apptentiveSecondaryLabel)

        // The color used for the background of the entire survey.
        #expect(UIColor.apptentiveGroupedBackground == .systemGroupedBackground)

        // The color used for the cell where the survey question is located.
        #expect(UIColor.apptentiveSecondaryGroupedBackground == .secondarySystemGroupedBackground)

        // The color to use for separators in e.g. table views.
        #expect(UIColor.apptentiveSeparator == .separator)

        // The color to use for images in a selected state for surveys.
        #expect(UIColor.apptentiveImageSelected == .apptentiveTint)

        // The color to use for images in a non-selected state for surveys.
        #expect(UIColor.apptentiveImageNotSelected == .apptentiveTint)

        // The background color to use for the submit button on surveys.
        #expect(UIColor.apptentiveSubmitButton == .apptentiveTint)

        // The background color to use for the footer which contains the terms and conditions for branched surveys.
        #expect(UIColor.apptentiveBranchedSurveyFooter == .tertiarySystemBackground)

        // The color to use for the survey footer label (Thank You text).
        #expect(UIColor.apptentiveSubmitStatusLabel == .apptentiveLabel)

        // The color to use for the terms of service label.
        #expect(UIColor.apptentiveTermsOfServiceLabel == .apptentiveTint)

        // The color to use for the submit button text color.
        #expect(UIColor.apptentiveSubmitButtonTitle == .white)

        // The color to use for submit button border.
        #expect(UIColor.apptentiveSubmitButtonBorder == .clear)

        // The color to use for the space between questions.
        #expect(UIColor.apptentiveQuestionSeparator == .clear)

        // The color to use for the unselected segments for branched surveys.
        #expect(UIColor.apptentiveUnselectedSurveyIndicatorSegment == .gray)

        // The color to use for the selected segments for branched surveys.
        #expect(UIColor.apptentiveSelectedSurveyIndicatorSegment == .apptentiveTint)

        // The color to use for the background of Message Center.
        #expect(UIColor.apptentiveMessageCenterBackground == .systemBackground)

        // The color to use for the button that deletes the attachment from the draft message.
        #expect(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: lightTC) == UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1))
        #expect(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: darkTC) == UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1))

        // The color to use for the compose box for Message Center.
        #expect(UIColor.apptentiveMessageCenterComposeBoxBackground == .systemBackground)

        // The color to use for the compose box separator.
        #expect(UIColor.apptentiveMessageCenterComposeBoxSeparator == .separator)

        // The color to use for text input borders when selected.
        #expect(UIColor.apptentiveTextInputBorderSelected == .lightGray)

        // The text color used for the disclaimer text.
        #expect(UIColor.apptentiveDisclaimerLabel == .lightGray)

        // MARK: Fonts

        // The font to use for placeholder for text inputs in message center.
        #expect(UIFont.apptentiveMessageCenterTextInputPlaceholder == .preferredFont(forTextStyle: .body))

        // The font to use for text inputs in message menter.
        #expect(UIFont.apptentiveMessageCenterTextInput == .preferredFont(forTextStyle: .body))

        // The font to use for placeholder text for text inputs in surveys.
        #expect(UIFont.apptentiveTextInputPlaceholder == .preferredFont(forTextStyle: .body))

        // The font to use for the SLA for message center.
        #expect(UIFont.apptentiveMessageCenterStatus == .preferredFont(forTextStyle: .footnote))

        // The font to use for the greeting title for message center.
        #expect(UIFont.apptentiveMessageCenterGreetingTitle == .preferredFont(forTextStyle: .headline))

        // The font to use for the greeting body for message center.
        #expect(UIFont.apptentiveMessageCenterGreetingBody == .preferredFont(forTextStyle: .body))

        // The font to use for attachment placeholder file extension labels.
        #expect(UIFont.apptentiveMessageCenterAttachmentLabel == .preferredFont(forTextStyle: .caption1))

        // The font used for all survey question labels.
        #expect(UIFont.apptentiveQuestionLabel == .preferredFont(forTextStyle: .headline))

        // The font used for the terms of service.
        #expect(UIFont.apptentiveTermsOfServiceLabel == .preferredFont(forTextStyle: .footnote))

        // The font used for all survey answer choice labels.
        #expect(UIFont.apptentiveChoiceLabel == .preferredFont(forTextStyle: .body))

        // The font used for the message body in message center.
        #expect(UIFont.apptentiveMessageLabel == .preferredFont(forTextStyle: .body))

        // The font used for the min and max labels for the range survey.
        #expect(UIFont.apptentiveMinMaxLabel == .preferredFont(forTextStyle: .footnote))

        // The font used for the sender label in message center.
        #expect(UIFont.apptentiveSenderLabel == .preferredFont(forTextStyle: .caption2))

        // The font used for the message date label in message center.
        #expect(UIFont.apptentiveMessageDateLabel == .preferredFont(forTextStyle: .caption2))

        // The font used for the instructions label for surveys.
        #expect(UIFont.apptentiveInstructionsLabel == .preferredFont(forTextStyle: .footnote))

        // The color to use for choice labels.
        #expect(UIColor.apptentiveChoiceLabel.resolvedColor(with: lightTC) == .apptentiveLabel.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveChoiceLabel.resolvedColor(with: darkTC) == .apptentiveLabel.resolvedColor(with: darkTC))

        // The font used for the survey introduction label.
        #expect(UIFont.apptentiveSurveyIntroductionLabel == .preferredFont(forTextStyle: .subheadline))

        // The font used for the survey footer label (Thank You text).
        #expect(UIFont.apptentiveSubmitStatusLabel == .preferredFont(forTextStyle: .headline))

        // The font used for the disclaimer text.
        #expect(UIFont.apptentiveDisclaimerLabel == .preferredFont(forTextStyle: .callout))

        // The font used for the submit button at the end of surveys.
        #expect(UIFont.apptentiveSubmitButtonTitle == .preferredFont(forTextStyle: .headline))

        // The font used for the multi- and single-line text inputs in surveys.
        #expect(UIFont.apptentiveTextInput == .preferredFont(forTextStyle: .body))
    }

    @MainActor func withApptentiveTheme() throws {
        Apptentive.applyApptentiveTheme()

        let bundle = Bundle(for: BundleFinder.self)
        guard let barTintColor = UIColor(named: "barTint", in: bundle, compatibleWith: nil),
            //let barForegroundColor = UIColor(named: "barForeground", in: bundle, compatibleWith: nil),
            let buttonTintColor = UIColor(named: "buttonTint", in: bundle, compatibleWith: nil),
            let apptentiveRangeControlBorder = UIColor(named: "apptentiveRangeControlBorder", in: bundle, compatibleWith: nil),
            let imageNotSelectedColor = UIColor(named: "imageNotSelected", in: bundle, compatibleWith: nil),
            let textInputBorderColor = UIColor(named: "textInputBorder", in: bundle, compatibleWith: nil),
            let textInputColor = UIColor(named: "textInput", in: bundle, compatibleWith: nil),
            let instructionsLabelColor = UIColor(named: "instructionsLabel", in: bundle, compatibleWith: nil),
            let choiceLabelColor = UIColor(named: "choiceLabel", in: bundle, compatibleWith: nil),
            let apptentiveGroupPrimaryColor = UIColor(named: "apptentiveGroupPrimary", in: bundle, compatibleWith: nil),
            let apptentiveGroupSecondaryColor = UIColor(named: "apptentiveGroupSecondary", in: bundle, compatibleWith: nil),
            let textInputBackgroundColor = UIColor(named: "textInputBackground", in: bundle, compatibleWith: nil),
            let termsOfServiceColor = UIColor(named: "termsOfService", in: bundle, compatibleWith: nil),
            let question = UIColor(named: "question", in: bundle, compatibleWith: nil),
            let messageBubbleInboundColor = UIColor(named: "messageBubbleInbound", in: bundle, compatibleWith: nil),
            let messageLabelInboundColor = UIColor(named: "messageLabelInbound", in: bundle, compatibleWith: nil),
            let messageBubbleOutboundColor = UIColor(named: "messageBubbleOutbound", in: bundle, compatibleWith: nil),
            let messageTextInputBorderColor = UIColor(named: "messageTextInputBorder", in: bundle, compatibleWith: nil),
            //            let dialogSeparator = UIColor(named: "dialogSeparator", in: bundle, compatibleWith: nil),
            //            let dialogText = UIColor(named: "dialogText", in: bundle, compatibleWith: nil),
            //            let dialogButtonText = UIColor(named: "dialogButtonText", in: bundle, compatibleWith: nil),
            let unselectedSurveyIndicatorColor = UIColor(named: "unselectedSurveyIndicator", in: bundle, compatibleWith: nil),
            let surveyGreeting = UIColor(named: "surveyGreetingText", in: bundle, compatibleWith: nil),
            let surveyImageChoice = UIColor(named: "surveyImageChoice", in: bundle, compatibleWith: nil),
            let attachmentDeleteButton = UIColor(named: "attachmentDeleteButton", in: bundle, compatibleWith: nil),
            let error = UIColor(named: "apptentiveError", in: bundle, compatibleWith: nil),
            let textInputPlaceholder = UIColor(named: "textInputPlaceholder", in: bundle, compatibleWith: nil),
            let textInputBorderSelected = UIColor(named: "textInputBorderSelected", in: bundle, compatibleWith: nil),
            //            let rangeNotSelectedSegmentBackground = UIColor(named: "rangeNotSelectedSegmentBackground", in: bundle, compatibleWith: nil),
            let disclaimerColor = UIColor(named: "disclaimer", in: bundle, compatibleWith: nil)
        else {
            throw TestError(reason: "Unable to load assets from test bundle")
        }

        #expect(ApptentiveNavigationController.preferredStatusBarStyle == .lightContent)

        // Increases the header height for surveys.
        #expect(ApptentiveNavigationController.prefersLargeHeader == false)

        // Determines height of the separator between questions.
        #expect(UITableView.apptentiveQuestionSeparatorHeight == 0)

        // The table view style to use for Apptentive UI.
        #expect(UITableView.Style.apptentive == .grouped)

        // The modal presentation style to use for Surveys and Message Center.
        #expect(UIModalPresentationStyle.apptentive == .fullScreen)

        // The style for call-to-action buttons in Apptentive UI.
        #expect(UIButton.apptentiveStyle == .radius(8))

        // MARK: Colors

        let lightTC = UITraitCollection(userInterfaceStyle: .light)
        let darkTC = UITraitCollection(userInterfaceStyle: .dark)

        // The color to use for the background in text inputs for message center.
        #expect(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: lightTC) == textInputBackgroundColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: darkTC) == textInputBackgroundColor.resolvedColor(with: darkTC))

        // The placeholder color to use for text inputs for message center.
        #expect(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: lightTC) == textInputPlaceholder.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: darkTC) == textInputPlaceholder.resolvedColor(with: darkTC))

        // The text color to use for all text inputs in message center.
        #expect(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: lightTC) == textInputColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: darkTC) == textInputColor.resolvedColor(with: darkTC))

        // The tint color for text inputs for surveys.
        #expect(UIColor.apptentivetextInputTint == .apptentiveTint)

        // The border color to use for the message text view.
        #expect(UIColor.apptentiveMessageCenterTextInputBorder.resolvedColor(with: lightTC) == messageTextInputBorderColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterTextInputBorder.resolvedColor(with: darkTC) == messageTextInputBorderColor.resolvedColor(with: darkTC))

        // The color to use for the attachment button for the compose view for message center.
        #expect(UIColor.apptentiveMessageCenterAttachmentButton == .apptentiveTint)

        // The color to use for the text view placeholder for the compose view for message center.
        #expect(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: lightTC) == textInputPlaceholder.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: darkTC) == textInputPlaceholder.resolvedColor(with: darkTC))

        // The color to use for the status message in message center.
        #expect(UIColor.apptentiveMessageCenterStatus.resolvedColor(with: lightTC) == textInputColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterStatus.resolvedColor(with: darkTC) == textInputColor.resolvedColor(with: darkTC))

        // The color to use for the greeting body on the greeting header view for message center.
        #expect(UIColor.apptentiveMessageCenterGreetingBody.resolvedColor(with: lightTC) == question.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterGreetingBody.resolvedColor(with: darkTC) == question.resolvedColor(with: darkTC))

        // The color to use for the greeting title on the greeting header view for message center.
        #expect(UIColor.apptentiveMessageCenterGreetingTitle.resolvedColor(with: lightTC) == surveyGreeting.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterGreetingTitle.resolvedColor(with: darkTC) == surveyGreeting.resolvedColor(with: darkTC))

        // The color to use for the message bubble view for inbound messages.
        #expect(UIColor.apptentiveMessageBubbleInbound.resolvedColor(with: lightTC) == messageBubbleInboundColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageBubbleInbound.resolvedColor(with: darkTC) == messageBubbleInboundColor.resolvedColor(with: darkTC))

        // The color to use for the message bubble view for outbound messages.
        #expect(UIColor.apptentiveMessageBubbleOutbound.resolvedColor(with: lightTC) == messageBubbleOutboundColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageBubbleOutbound.resolvedColor(with: darkTC) == messageBubbleOutboundColor.resolvedColor(with: darkTC))

        // The color to use for message labels for the inbound message body.
        #expect(UIColor.apptentiveMessageLabelInbound.resolvedColor(with: lightTC) == messageLabelInboundColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageLabelInbound.resolvedColor(with: darkTC) == messageLabelInboundColor.resolvedColor(with: darkTC))

        // The color to use for message labels for the outbound message body.
        #expect(UIColor.apptentiveMessageLabelOutbound.resolvedColor(with: lightTC) == termsOfServiceColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageLabelOutbound.resolvedColor(with: darkTC) == termsOfServiceColor.resolvedColor(with: darkTC))

        // The color to use for labels in a non-error state.
        #expect(UIColor.apptentiveQuestionLabel.resolvedColor(with: lightTC) == question.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveQuestionLabel.resolvedColor(with: darkTC) == question.resolvedColor(with: darkTC))

        // The color to use for instruction labels.
        #expect(UIColor.apptentiveInstructionsLabel.resolvedColor(with: lightTC) == instructionsLabelColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveInstructionsLabel.resolvedColor(with: darkTC) == instructionsLabelColor.resolvedColor(with: darkTC))

        // The color to use for choice labels.
        #expect(UIColor.apptentiveChoiceLabel.resolvedColor(with: lightTC) == choiceLabelColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveChoiceLabel.resolvedColor(with: darkTC) == choiceLabelColor.resolvedColor(with: darkTC))

        // The color to use for UI elements to indicate an error state.
        #expect(UIColor.apptentiveError.resolvedColor(with: lightTC) == error.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveError.resolvedColor(with: darkTC) == error.resolvedColor(with: darkTC))

        // The color to use for labels of primary prominance.
        #expect(UIColor.apptentiveLabel == .label)

        // The tint/accent color to use for buttons and similar controls in Apptentive interaction UI.
        if #available(iOS 15.0, *) {
            #expect(UIColor.apptentiveTint == .tintColor)
        } else {
            #expect(UIColor.apptentiveTint == .systemBlue)
        }

        // The color to use for labels of secondary prominence.
        #expect(UIColor.apptentiveSecondaryLabel == .secondaryLabel)

        // The border color to use for the segmented control for range surveys.
        #expect(UIColor.apptentiveRangeControlBorder.resolvedColor(with: lightTC) == apptentiveRangeControlBorder.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveRangeControlBorder.resolvedColor(with: darkTC) == apptentiveRangeControlBorder.resolvedColor(with: darkTC))

        // The color to use for the survey introduction text.
        #expect(UIColor.apptentiveSurveyIntroduction.resolvedColor(with: lightTC) == surveyGreeting.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveSurveyIntroduction.resolvedColor(with: darkTC) == surveyGreeting.resolvedColor(with: darkTC))

        // The color to use for the borders of text fields and text views.
        #expect(UIColor.apptentiveTextInputBorder.resolvedColor(with: lightTC) == textInputBorderColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveTextInputBorder.resolvedColor(with: darkTC) == textInputBorderColor.resolvedColor(with: darkTC))

        // The color to use for text fields and text views.
        #expect(UIColor.apptentiveTextInputBackground.resolvedColor(with: lightTC) == textInputBackgroundColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveTextInputBackground.resolvedColor(with: darkTC) == textInputBackgroundColor.resolvedColor(with: darkTC))

        // The color to use for text within text fields and text views.
        #expect(UIColor.apptentiveTextInput.resolvedColor(with: lightTC) == textInputColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveTextInput.resolvedColor(with: darkTC) == textInputColor.resolvedColor(with: darkTC))

        // The color used for min and max labels for the range survey.
        #expect(UIColor.apptentiveMinMaxLabel == .apptentiveSecondaryLabel)

        // The color used for the background of the entire survey.
        #expect(UIColor.apptentiveGroupedBackground.resolvedColor(with: lightTC) == apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveGroupedBackground.resolvedColor(with: darkTC) == apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color used for the cell where the survey question is located.
        #expect(UIColor.apptentiveSecondaryGroupedBackground.resolvedColor(with: lightTC) == apptentiveGroupSecondaryColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveSecondaryGroupedBackground.resolvedColor(with: darkTC) == apptentiveGroupSecondaryColor.resolvedColor(with: darkTC))

        // The color to use for separators in e.g. table views.
        #expect(UIColor.apptentiveSeparator.resolvedColor(with: lightTC) == apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveSeparator.resolvedColor(with: darkTC) == apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color to use for images in a selected state for surveys.
        #expect(UIColor.apptentiveImageSelected.resolvedColor(with: lightTC) == surveyImageChoice.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveImageSelected.resolvedColor(with: darkTC) == surveyImageChoice.resolvedColor(with: darkTC))

        // The color to use for images in a non-selected state for surveys.
        #expect(UIColor.apptentiveImageNotSelected.resolvedColor(with: lightTC) == imageNotSelectedColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveImageNotSelected.resolvedColor(with: darkTC) == imageNotSelectedColor.resolvedColor(with: darkTC))

        // The background color to use for the submit button on surveys.
        #expect(UIColor.apptentiveSubmitButton.resolvedColor(with: lightTC) == buttonTintColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveSubmitButton.resolvedColor(with: darkTC) == buttonTintColor.resolvedColor(with: darkTC))

        // The background color to use for the footer which contains the terms and conditions for branched surveys.
        #expect(UIColor.apptentiveBranchedSurveyFooter.resolvedColor(with: lightTC) == barTintColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveBranchedSurveyFooter.resolvedColor(with: darkTC) == barTintColor.resolvedColor(with: darkTC))

        // The color to use for the survey footer label (Thank You text).
        #expect(UIColor.apptentiveSubmitStatusLabel == .apptentiveLabel)

        // The color to use for the terms of service label.
        #expect(UIColor.apptentiveTermsOfServiceLabel.resolvedColor(with: lightTC) == termsOfServiceColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveTermsOfServiceLabel.resolvedColor(with: darkTC) == termsOfServiceColor.resolvedColor(with: darkTC))

        // The color to use for the submit button text color.
        #expect(UIColor.apptentiveSubmitButtonTitle == .white)

        // The color to use for submit button border.
        #expect(UIColor.apptentiveSubmitButtonBorder == .clear)

        // The color to use for the space between questions.
        #expect(UIColor.apptentiveQuestionSeparator == .clear)

        // The color to use for the unselected segments for branched surveys.
        #expect(UIColor.apptentiveUnselectedSurveyIndicatorSegment.resolvedColor(with: lightTC) == unselectedSurveyIndicatorColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveUnselectedSurveyIndicatorSegment.resolvedColor(with: darkTC) == unselectedSurveyIndicatorColor.resolvedColor(with: darkTC))

        // The color to use for the selected segments for branched surveys.
        #expect(UIColor.apptentiveSelectedSurveyIndicatorSegment.resolvedColor(with: lightTC) == buttonTintColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveSelectedSurveyIndicatorSegment.resolvedColor(with: darkTC) == buttonTintColor.resolvedColor(with: darkTC))

        // The color to use for the background of Message Center.
        #expect(UIColor.apptentiveMessageCenterBackground.resolvedColor(with: lightTC) == apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterBackground.resolvedColor(with: darkTC) == apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color to use for the button that deletes the attachment from the draft message.
        #expect(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: lightTC) == attachmentDeleteButton.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: darkTC) == attachmentDeleteButton.resolvedColor(with: darkTC))

        // The color to use for the compose box for Message Center.
        #expect(UIColor.apptentiveMessageCenterComposeBoxBackground.resolvedColor(with: lightTC) == apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveMessageCenterComposeBoxBackground.resolvedColor(with: darkTC) == apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color to use for the compose box separator.
        #expect(UIColor.apptentiveMessageCenterComposeBoxSeparator == .separator)

        // The color to use for text input borders when selected.
        #expect(UIColor.apptentiveTextInputBorderSelected.resolvedColor(with: lightTC) == textInputBorderSelected.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveTextInputBorderSelected.resolvedColor(with: darkTC) == textInputBorderSelected.resolvedColor(with: darkTC))

        // The text color used for the disclaimer text.
        #expect(UIColor.apptentiveDisclaimerLabel.resolvedColor(with: lightTC) == disclaimerColor.resolvedColor(with: lightTC))
        #expect(UIColor.apptentiveDisclaimerLabel.resolvedColor(with: darkTC) == disclaimerColor.resolvedColor(with: darkTC))

        // MARK: Fonts

        // The font to use for placeholder for text inputs in message center.
        #expect(UIFont.apptentiveMessageCenterTextInputPlaceholder == .preferredFont(forTextStyle: .body))

        // The font to use for text inputs in message menter.
        #expect(UIFont.apptentiveMessageCenterTextInput == .preferredFont(forTextStyle: .body))

        // The font to use for placeholder text for text inputs in surveys.
        #expect(UIFont.apptentiveTextInputPlaceholder == .preferredFont(forTextStyle: .body))

        // The font to use for the SLA for message center.
        #expect(UIFont.apptentiveMessageCenterStatus == .preferredFont(forTextStyle: .footnote))

        // The font to use for the greeting title for message center.
        #expect(UIFont.apptentiveMessageCenterGreetingTitle == .preferredFont(forTextStyle: .headline))

        // The font to use for the greeting body for message center.
        #expect(UIFont.apptentiveMessageCenterGreetingBody == .preferredFont(forTextStyle: .body))

        // The font to use for attachment placeholder file extension labels.
        #expect(UIFont.apptentiveMessageCenterAttachmentLabel == .preferredFont(forTextStyle: .caption1))

        // The font used for all survey question labels.
        #expect(UIFont.apptentiveQuestionLabel == .preferredFont(forTextStyle: .body))

        // The font used for the terms of service.
        #expect(UIFont.apptentiveTermsOfServiceLabel == .preferredFont(forTextStyle: .footnote))

        // The font used for all survey answer choice labels.
        #expect(UIFont.apptentiveChoiceLabel == .preferredFont(forTextStyle: .body))

        // The font used for the message body in message center.
        #expect(UIFont.apptentiveMessageLabel == .preferredFont(forTextStyle: .body))

        // The font used for the min and max labels for the range survey.
        #expect(UIFont.apptentiveMinMaxLabel == .preferredFont(forTextStyle: .footnote))

        // The font used for the sender label in message center.
        #expect(UIFont.apptentiveSenderLabel == .preferredFont(forTextStyle: .caption2))

        // The font used for the message date label in message center.
        #expect(UIFont.apptentiveMessageDateLabel == .preferredFont(forTextStyle: .caption2))

        // The font used for the instructions label for surveys.
        #expect(UIFont.apptentiveInstructionsLabel == .preferredFont(forTextStyle: .footnote))

        // The font used for the survey introduction label.
        #expect(UIFont.apptentiveSurveyIntroductionLabel == .preferredFont(forTextStyle: .subheadline))

        // The font used for the survey footer label (Thank You text).
        #expect(UIFont.apptentiveSubmitStatusLabel == .preferredFont(forTextStyle: .headline))

        // The font used for the disclaimer text.
        #expect(UIFont.apptentiveDisclaimerLabel == .preferredFont(forTextStyle: .callout))

        // The font used for the submit button at the end of surveys.
        #expect(UIFont.apptentiveSubmitButtonTitle == .preferredFont(forTextStyle: .headline))

        // The font used for the multi- and single-line text inputs in surveys.
        #expect(UIFont.apptentiveTextInput == .preferredFont(forTextStyle: .body))
    }
}
