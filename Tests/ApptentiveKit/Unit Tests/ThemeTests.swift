//
//  ThemeTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 4/2/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

final class ThemeTests: XCTestCase {
    func testTheming() {
        withNoTheme()
        withApptentiveTheme()
    }

    func withNoTheme() {
        XCTAssertEqual(ApptentiveNavigationController.preferredStatusBarStyle, .default)

        // Increases the header height for surveys.
        XCTAssertEqual(ApptentiveNavigationController.prefersLargeHeader, false)

        // Determines height of the separator between questions.
        XCTAssertEqual(UITableView.apptentiveQuestionSeparatorHeight, 0)

        // The table view style to use for Apptentive UI.
        XCTAssertEqual(UITableView.Style.apptentive, .insetGrouped)

        // The modal presentation style to use for Surveys and Message Center.
        XCTAssertEqual(UIModalPresentationStyle.apptentive, .pageSheet)

        // The style for call-to-action buttons in Apptentive UI.
        XCTAssertEqual(UIButton.apptentiveStyle, .pill)

        // MARK: Colors

        let lightTC = UITraitCollection(userInterfaceStyle: .light)
        let darkTC = UITraitCollection(userInterfaceStyle: .dark)

        // The color to use for the background in text inputs for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: lightTC), .white)
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: darkTC), .black)

        // The placeholder color to use for text inputs for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputPlaceholder, .placeholderText)

        // The text color to use for all text inputs in message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: lightTC), .label.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: darkTC), .label.resolvedColor(with: darkTC))

        // The tint color for text inputs for surveys.
        XCTAssertEqual(UIColor.apptentivetextInputTint, .apptentiveTint)

        // The border color to use for the message text view.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBorder, .lightGray)

        // The color to use for the attachment button for the compose view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterAttachmentButton, .apptentiveTint)

        // The color to use for the text view placeholder for the compose view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageTextInputPlaceholder, .placeholderText)

        // The color to use for the status message in message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterStatus, .apptentiveSecondaryLabel)

        // The color to use for the greeting body on the greeting header view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterGreetingBody, .apptentiveSecondaryLabel)

        // The color to use for the greeting title on the greeting header view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterGreetingTitle, .apptentiveSecondaryLabel)

        // The color to use for the message bubble view for inbound messages.
        XCTAssertEqual(UIColor.apptentiveMessageBubbleInbound, .darkGray)

        // The color to use for the message bubble view for outbound messages.
        XCTAssertEqual(UIColor.apptentiveMessageBubbleOutbound, UIColor(red: 0, green: 0.42, blue: 1, alpha: 1))

        // The color to use for message labels for the inbound message body.
        XCTAssertEqual(UIColor.apptentiveMessageLabelInbound, .white)

        // The color to use for message labels for the outbound message body.
        XCTAssertEqual(UIColor.apptentiveMessageLabelOutbound, .white)

        // The color to use for labels in a non-error state.
        XCTAssertEqual(UIColor.apptentiveQuestionLabel, .apptentiveLabel)

        // The color to use for instruction labels.
        XCTAssertEqual(UIColor.apptentiveInstructionsLabel, .apptentiveSecondaryLabel)

        // The color to use for UI elements to indicate an error state.
        XCTAssertEqual(UIColor.apptentiveError.resolvedColor(with: lightTC), UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1))
        XCTAssertEqual(UIColor.apptentiveError.resolvedColor(with: darkTC), UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1))

        // The color to use for labels of primary prominance.
        XCTAssertEqual(UIColor.apptentiveLabel, .label)

        // The tint/accent color to use for buttons and similar controls in Apptentive interaction UI.
        if #available(iOS 15.0, *) {
            XCTAssertEqual(UIColor.apptentiveTint, .tintColor)
        } else {
            XCTAssertEqual(UIColor.apptentiveTint, .systemBlue)
        }

        // The color to use for labels of secondary prominence.
        XCTAssertEqual(UIColor.apptentiveSecondaryLabel, .secondaryLabel)

        // The border color to use for the segmented control for range surveys.
        XCTAssertEqual(UIColor.apptentiveRangeControlBorder, .clear)

        // The color to use for the survey introduction text.
        XCTAssertEqual(UIColor.apptentiveSurveyIntroduction, .apptentiveLabel)

        // The color to use for the borders of text fields and text views.
        XCTAssertEqual(UIColor.apptentiveTextInputBorder, .lightGray)

        // The color to use for text fields and text views.
        XCTAssertEqual(UIColor.apptentiveTextInputBackground.resolvedColor(with: lightTC), .white)
        XCTAssertEqual(UIColor.apptentiveTextInputBackground.resolvedColor(with: darkTC), .black)

        // The color to use for text within text fields and text views.
        XCTAssertEqual(UIColor.apptentiveTextInput.resolvedColor(with: lightTC), .label.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveTextInput.resolvedColor(with: darkTC), .label.resolvedColor(with: darkTC))

        // The color used for min and max labels for the range survey.
        XCTAssertEqual(UIColor.apptentiveMinMaxLabel, .apptentiveSecondaryLabel)

        // The color used for the background of the entire survey.
        XCTAssertEqual(UIColor.apptentiveGroupedBackground, .systemGroupedBackground)

        // The color used for the cell where the survey question is located.
        XCTAssertEqual(UIColor.apptentiveSecondaryGroupedBackground, .secondarySystemGroupedBackground)

        // The color to use for separators in e.g. table views.
        XCTAssertEqual(UIColor.apptentiveSeparator, .separator)

        // The color to use for images in a selected state for surveys.
        XCTAssertEqual(UIColor.apptentiveImageSelected, .apptentiveTint)

        // The color to use for images in a non-selected state for surveys.
        XCTAssertEqual(UIColor.apptentiveImageNotSelected, .apptentiveTint)

        // The background color to use for the submit button on surveys.
        XCTAssertEqual(UIColor.apptentiveSubmitButton, .apptentiveTint)

        // The background color to use for the footer which contains the terms and conditions for branched surveys.
        XCTAssertEqual(UIColor.apptentiveBranchedSurveyFooter, .tertiarySystemBackground)

        // The color to use for the survey footer label (Thank You text).
        XCTAssertEqual(UIColor.apptentiveSubmitStatusLabel, .apptentiveLabel)

        // The color to use for the terms of service label.
        XCTAssertEqual(UIColor.apptentiveTermsOfServiceLabel, .apptentiveTint)

        // The color to use for the submit button text color.
        XCTAssertEqual(UIColor.apptentiveSubmitButtonTitle, .white)

        // The color to use for submit button border.
        XCTAssertEqual(UIColor.apptentiveSubmitButtonBorder, .clear)

        // The color to use for the space between questions.
        XCTAssertEqual(UIColor.apptentiveQuestionSeparator, .clear)

        // The color to use for the unselected segments for branched surveys.
        XCTAssertEqual(UIColor.apptentiveUnselectedSurveyIndicatorSegment, .gray)

        // The color to use for the selected segments for branched surveys.
        XCTAssertEqual(UIColor.apptentiveSelectedSurveyIndicatorSegment, .apptentiveTint)

        // The color to use for the background of Message Center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterBackground, .systemBackground)

        // The color to use for the button that deletes the attachment from the draft message.
        XCTAssertEqual(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: lightTC), UIColor(red: 0.86, green: 0.1, blue: 0, alpha: 1))
        XCTAssertEqual(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: darkTC), UIColor(red: 1, green: 0.28, blue: 0.24, alpha: 1))

        // The color to use for the compose box for Message Center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterComposeBoxBackground, .systemBackground)

        // The color to use for the compose box separator.
        XCTAssertEqual(UIColor.apptentiveMessageCenterComposeBoxSeparator, .separator)

        // The color to use for text input borders when selected.
        XCTAssertEqual(UIColor.apptentiveTextInputBorderSelected, .lightGray)

        // The text color used for the disclaimer text.
        XCTAssertEqual(UIColor.apptentiveDisclaimerLabel, .lightGray)

        // MARK: Fonts

        // The font to use for placeholder for text inputs in message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterTextInputPlaceholder, .preferredFont(forTextStyle: .body))

        // The font to use for text inputs in message menter.
        XCTAssertEqual(UIFont.apptentiveMessageCenterTextInput, .preferredFont(forTextStyle: .body))

        // The font to use for placeholder text for text inputs in surveys.
        XCTAssertEqual(UIFont.apptentiveTextInputPlaceholder, .preferredFont(forTextStyle: .body))

        // The font to use for the SLA for message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterStatus, .preferredFont(forTextStyle: .footnote))

        // The font to use for the greeting title for message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterGreetingTitle, .preferredFont(forTextStyle: .headline))

        // The font to use for the greeting body for message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterGreetingBody, .preferredFont(forTextStyle: .body))

        // The font to use for attachment placeholder file extension labels.
        XCTAssertEqual(UIFont.apptentiveMessageCenterAttachmentLabel, .preferredFont(forTextStyle: .caption1))

        // The font used for all survey question labels.
        XCTAssertEqual(UIFont.apptentiveQuestionLabel, .preferredFont(forTextStyle: .headline))

        // The font used for the terms of service.
        XCTAssertEqual(UIFont.apptentiveTermsOfServiceLabel, .preferredFont(forTextStyle: .footnote))

        // The font used for all survey answer choice labels.
        XCTAssertEqual(UIFont.apptentiveChoiceLabel, .preferredFont(forTextStyle: .body))

        // The font used for the message body in message center.
        XCTAssertEqual(UIFont.apptentiveMessageLabel, .preferredFont(forTextStyle: .body))

        // The font used for the min and max labels for the range survey.
        XCTAssertEqual(UIFont.apptentiveMinMaxLabel, .preferredFont(forTextStyle: .footnote))

        // The font used for the sender label in message center.
        XCTAssertEqual(UIFont.apptentiveSenderLabel, .preferredFont(forTextStyle: .caption2))

        // The font used for the message date label in message center.
        XCTAssertEqual(UIFont.apptentiveMessageDateLabel, .preferredFont(forTextStyle: .caption2))

        // The font used for the instructions label for surveys.
        XCTAssertEqual(UIFont.apptentiveInstructionsLabel, .preferredFont(forTextStyle: .footnote))

        // The color to use for choice labels.
        XCTAssertEqual(UIColor.apptentiveChoiceLabel.resolvedColor(with: lightTC), .apptentiveLabel.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveChoiceLabel.resolvedColor(with: darkTC), .apptentiveLabel.resolvedColor(with: darkTC))

        // The font used for the survey introduction label.
        XCTAssertEqual(UIFont.apptentiveSurveyIntroductionLabel, .preferredFont(forTextStyle: .subheadline))

        // The font used for the survey footer label (Thank You text).
        XCTAssertEqual(UIFont.apptentiveSubmitStatusLabel, .preferredFont(forTextStyle: .headline))

        // The font used for the disclaimer text.
        XCTAssertEqual(UIFont.apptentiveDisclaimerLabel, .preferredFont(forTextStyle: .callout))

        // The font used for the submit button at the end of surveys.
        XCTAssertEqual(UIFont.apptentiveSubmitButtonTitle, .preferredFont(forTextStyle: .headline))

        // The font used for the multi- and single-line text inputs in surveys.
        XCTAssertEqual(UIFont.apptentiveTextInput, .preferredFont(forTextStyle: .body))
    }

    func withApptentiveTheme() {
        Apptentive.applyApptentiveTheme()

        let bundle = Bundle(for: Self.self)
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
            return XCTFail("Unable to load assets from test bundle")
        }

        XCTAssertEqual(ApptentiveNavigationController.preferredStatusBarStyle, .lightContent)

        // Increases the header height for surveys.
        XCTAssertEqual(ApptentiveNavigationController.prefersLargeHeader, false)

        // Determines height of the separator between questions.
        XCTAssertEqual(UITableView.apptentiveQuestionSeparatorHeight, 0)

        // The table view style to use for Apptentive UI.
        XCTAssertEqual(UITableView.Style.apptentive, .grouped)

        // The modal presentation style to use for Surveys and Message Center.
        XCTAssertEqual(UIModalPresentationStyle.apptentive, .fullScreen)

        // The style for call-to-action buttons in Apptentive UI.
        XCTAssertEqual(UIButton.apptentiveStyle, .radius(8))

        // MARK: Colors

        let lightTC = UITraitCollection(userInterfaceStyle: .light)
        let darkTC = UITraitCollection(userInterfaceStyle: .dark)

        // The color to use for the background in text inputs for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: lightTC), textInputBackgroundColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBackground.resolvedColor(with: darkTC), textInputBackgroundColor.resolvedColor(with: darkTC))

        // The placeholder color to use for text inputs for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: lightTC), textInputPlaceholder.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: darkTC), textInputPlaceholder.resolvedColor(with: darkTC))

        // The text color to use for all text inputs in message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: lightTC), textInputColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInput.resolvedColor(with: darkTC), textInputColor.resolvedColor(with: darkTC))

        // The tint color for text inputs for surveys.
        XCTAssertEqual(UIColor.apptentivetextInputTint, .apptentiveTint)

        // The border color to use for the message text view.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBorder.resolvedColor(with: lightTC), messageTextInputBorderColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputBorder.resolvedColor(with: darkTC), messageTextInputBorderColor.resolvedColor(with: darkTC))

        // The color to use for the attachment button for the compose view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterAttachmentButton, .apptentiveTint)

        // The color to use for the text view placeholder for the compose view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: lightTC), textInputPlaceholder.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterTextInputPlaceholder.resolvedColor(with: darkTC), textInputPlaceholder.resolvedColor(with: darkTC))

        // The color to use for the status message in message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterStatus.resolvedColor(with: lightTC), textInputColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterStatus.resolvedColor(with: darkTC), textInputColor.resolvedColor(with: darkTC))

        // The color to use for the greeting body on the greeting header view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterGreetingBody.resolvedColor(with: lightTC), question.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterGreetingBody.resolvedColor(with: darkTC), question.resolvedColor(with: darkTC))

        // The color to use for the greeting title on the greeting header view for message center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterGreetingTitle.resolvedColor(with: lightTC), surveyGreeting.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterGreetingTitle.resolvedColor(with: darkTC), surveyGreeting.resolvedColor(with: darkTC))

        // The color to use for the message bubble view for inbound messages.
        XCTAssertEqual(UIColor.apptentiveMessageBubbleInbound.resolvedColor(with: lightTC), messageBubbleInboundColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageBubbleInbound.resolvedColor(with: darkTC), messageBubbleInboundColor.resolvedColor(with: darkTC))

        // The color to use for the message bubble view for outbound messages.
        XCTAssertEqual(UIColor.apptentiveMessageBubbleOutbound.resolvedColor(with: lightTC), messageBubbleOutboundColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageBubbleOutbound.resolvedColor(with: darkTC), messageBubbleOutboundColor.resolvedColor(with: darkTC))

        // The color to use for message labels for the inbound message body.
        XCTAssertEqual(UIColor.apptentiveMessageLabelInbound.resolvedColor(with: lightTC), messageLabelInboundColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageLabelInbound.resolvedColor(with: darkTC), messageLabelInboundColor.resolvedColor(with: darkTC))

        // The color to use for message labels for the outbound message body.
        XCTAssertEqual(UIColor.apptentiveMessageLabelOutbound.resolvedColor(with: lightTC), termsOfServiceColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageLabelOutbound.resolvedColor(with: darkTC), termsOfServiceColor.resolvedColor(with: darkTC))

        // The color to use for labels in a non-error state.
        XCTAssertEqual(UIColor.apptentiveQuestionLabel.resolvedColor(with: lightTC), question.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveQuestionLabel.resolvedColor(with: darkTC), question.resolvedColor(with: darkTC))

        // The color to use for instruction labels.
        XCTAssertEqual(UIColor.apptentiveInstructionsLabel.resolvedColor(with: lightTC), instructionsLabelColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveInstructionsLabel.resolvedColor(with: darkTC), instructionsLabelColor.resolvedColor(with: darkTC))

        // The color to use for choice labels.
        XCTAssertEqual(UIColor.apptentiveChoiceLabel.resolvedColor(with: lightTC), choiceLabelColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveChoiceLabel.resolvedColor(with: darkTC), choiceLabelColor.resolvedColor(with: darkTC))

        // The color to use for UI elements to indicate an error state.
        XCTAssertEqual(UIColor.apptentiveError.resolvedColor(with: lightTC), error.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveError.resolvedColor(with: darkTC), error.resolvedColor(with: darkTC))

        // The color to use for labels of primary prominance.
        XCTAssertEqual(UIColor.apptentiveLabel, .label)

        // The tint/accent color to use for buttons and similar controls in Apptentive interaction UI.
        if #available(iOS 15.0, *) {
            XCTAssertEqual(UIColor.apptentiveTint, .tintColor)
        } else {
            XCTAssertEqual(UIColor.apptentiveTint, .systemBlue)
        }

        // The color to use for labels of secondary prominence.
        XCTAssertEqual(UIColor.apptentiveSecondaryLabel, .secondaryLabel)

        // The border color to use for the segmented control for range surveys.
        XCTAssertEqual(UIColor.apptentiveRangeControlBorder.resolvedColor(with: lightTC), apptentiveRangeControlBorder.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveRangeControlBorder.resolvedColor(with: darkTC), apptentiveRangeControlBorder.resolvedColor(with: darkTC))

        // The color to use for the survey introduction text.
        XCTAssertEqual(UIColor.apptentiveSurveyIntroduction.resolvedColor(with: lightTC), surveyGreeting.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveSurveyIntroduction.resolvedColor(with: darkTC), surveyGreeting.resolvedColor(with: darkTC))

        // The color to use for the borders of text fields and text views.
        XCTAssertEqual(UIColor.apptentiveTextInputBorder.resolvedColor(with: lightTC), textInputBorderColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveTextInputBorder.resolvedColor(with: darkTC), textInputBorderColor.resolvedColor(with: darkTC))

        // The color to use for text fields and text views.
        XCTAssertEqual(UIColor.apptentiveTextInputBackground.resolvedColor(with: lightTC), textInputBackgroundColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveTextInputBackground.resolvedColor(with: darkTC), textInputBackgroundColor.resolvedColor(with: darkTC))

        // The color to use for text within text fields and text views.
        XCTAssertEqual(UIColor.apptentiveTextInput.resolvedColor(with: lightTC), textInputColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveTextInput.resolvedColor(with: darkTC), textInputColor.resolvedColor(with: darkTC))

        // The color used for min and max labels for the range survey.
        XCTAssertEqual(UIColor.apptentiveMinMaxLabel, .apptentiveSecondaryLabel)

        // The color used for the background of the entire survey.
        XCTAssertEqual(UIColor.apptentiveGroupedBackground.resolvedColor(with: lightTC), apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveGroupedBackground.resolvedColor(with: darkTC), apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color used for the cell where the survey question is located.
        XCTAssertEqual(UIColor.apptentiveSecondaryGroupedBackground.resolvedColor(with: lightTC), apptentiveGroupSecondaryColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveSecondaryGroupedBackground.resolvedColor(with: darkTC), apptentiveGroupSecondaryColor.resolvedColor(with: darkTC))

        // The color to use for separators in e.g. table views.
        XCTAssertEqual(UIColor.apptentiveSeparator.resolvedColor(with: lightTC), apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveSeparator.resolvedColor(with: darkTC), apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color to use for images in a selected state for surveys.
        XCTAssertEqual(UIColor.apptentiveImageSelected.resolvedColor(with: lightTC), surveyImageChoice.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveImageSelected.resolvedColor(with: darkTC), surveyImageChoice.resolvedColor(with: darkTC))

        // The color to use for images in a non-selected state for surveys.
        XCTAssertEqual(UIColor.apptentiveImageNotSelected.resolvedColor(with: lightTC), imageNotSelectedColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveImageNotSelected.resolvedColor(with: darkTC), imageNotSelectedColor.resolvedColor(with: darkTC))

        // The background color to use for the submit button on surveys.
        XCTAssertEqual(UIColor.apptentiveSubmitButton.resolvedColor(with: lightTC), buttonTintColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveSubmitButton.resolvedColor(with: darkTC), buttonTintColor.resolvedColor(with: darkTC))

        // The background color to use for the footer which contains the terms and conditions for branched surveys.
        XCTAssertEqual(UIColor.apptentiveBranchedSurveyFooter.resolvedColor(with: lightTC), barTintColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveBranchedSurveyFooter.resolvedColor(with: darkTC), barTintColor.resolvedColor(with: darkTC))

        // The color to use for the survey footer label (Thank You text).
        XCTAssertEqual(UIColor.apptentiveSubmitStatusLabel, .apptentiveLabel)

        // The color to use for the terms of service label.
        XCTAssertEqual(UIColor.apptentiveTermsOfServiceLabel.resolvedColor(with: lightTC), termsOfServiceColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveTermsOfServiceLabel.resolvedColor(with: darkTC), termsOfServiceColor.resolvedColor(with: darkTC))

        // The color to use for the submit button text color.
        XCTAssertEqual(UIColor.apptentiveSubmitButtonTitle, .white)

        // The color to use for submit button border.
        XCTAssertEqual(UIColor.apptentiveSubmitButtonBorder, .clear)

        // The color to use for the space between questions.
        XCTAssertEqual(UIColor.apptentiveQuestionSeparator, .clear)

        // The color to use for the unselected segments for branched surveys.
        XCTAssertEqual(UIColor.apptentiveUnselectedSurveyIndicatorSegment.resolvedColor(with: lightTC), unselectedSurveyIndicatorColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveUnselectedSurveyIndicatorSegment.resolvedColor(with: darkTC), unselectedSurveyIndicatorColor.resolvedColor(with: darkTC))

        // The color to use for the selected segments for branched surveys.
        XCTAssertEqual(UIColor.apptentiveSelectedSurveyIndicatorSegment.resolvedColor(with: lightTC), buttonTintColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveSelectedSurveyIndicatorSegment.resolvedColor(with: darkTC), buttonTintColor.resolvedColor(with: darkTC))

        // The color to use for the background of Message Center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterBackground.resolvedColor(with: lightTC), apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterBackground.resolvedColor(with: darkTC), apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color to use for the button that deletes the attachment from the draft message.
        XCTAssertEqual(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: lightTC), attachmentDeleteButton.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveAttachmentRemoveButton.resolvedColor(with: darkTC), attachmentDeleteButton.resolvedColor(with: darkTC))

        // The color to use for the compose box for Message Center.
        XCTAssertEqual(UIColor.apptentiveMessageCenterComposeBoxBackground.resolvedColor(with: lightTC), apptentiveGroupPrimaryColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveMessageCenterComposeBoxBackground.resolvedColor(with: darkTC), apptentiveGroupPrimaryColor.resolvedColor(with: darkTC))

        // The color to use for the compose box separator.
        XCTAssertEqual(UIColor.apptentiveMessageCenterComposeBoxSeparator, .separator)

        // The color to use for text input borders when selected.
        XCTAssertEqual(UIColor.apptentiveTextInputBorderSelected.resolvedColor(with: lightTC), textInputBorderSelected.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveTextInputBorderSelected.resolvedColor(with: darkTC), textInputBorderSelected.resolvedColor(with: darkTC))

        // The text color used for the disclaimer text.
        XCTAssertEqual(UIColor.apptentiveDisclaimerLabel.resolvedColor(with: lightTC), disclaimerColor.resolvedColor(with: lightTC))
        XCTAssertEqual(UIColor.apptentiveDisclaimerLabel.resolvedColor(with: darkTC), disclaimerColor.resolvedColor(with: darkTC))

        // MARK: Fonts

        // The font to use for placeholder for text inputs in message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterTextInputPlaceholder, .preferredFont(forTextStyle: .body))

        // The font to use for text inputs in message menter.
        XCTAssertEqual(UIFont.apptentiveMessageCenterTextInput, .preferredFont(forTextStyle: .body))

        // The font to use for placeholder text for text inputs in surveys.
        XCTAssertEqual(UIFont.apptentiveTextInputPlaceholder, .preferredFont(forTextStyle: .body))

        // The font to use for the SLA for message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterStatus, .preferredFont(forTextStyle: .footnote))

        // The font to use for the greeting title for message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterGreetingTitle, .preferredFont(forTextStyle: .headline))

        // The font to use for the greeting body for message center.
        XCTAssertEqual(UIFont.apptentiveMessageCenterGreetingBody, .preferredFont(forTextStyle: .body))

        // The font to use for attachment placeholder file extension labels.
        XCTAssertEqual(UIFont.apptentiveMessageCenterAttachmentLabel, .preferredFont(forTextStyle: .caption1))

        // The font used for all survey question labels.
        XCTAssertEqual(UIFont.apptentiveQuestionLabel, .preferredFont(forTextStyle: .body))

        // The font used for the terms of service.
        XCTAssertEqual(UIFont.apptentiveTermsOfServiceLabel, .preferredFont(forTextStyle: .footnote))

        // The font used for all survey answer choice labels.
        XCTAssertEqual(UIFont.apptentiveChoiceLabel, .preferredFont(forTextStyle: .body))

        // The font used for the message body in message center.
        XCTAssertEqual(UIFont.apptentiveMessageLabel, .preferredFont(forTextStyle: .body))

        // The font used for the min and max labels for the range survey.
        XCTAssertEqual(UIFont.apptentiveMinMaxLabel, .preferredFont(forTextStyle: .footnote))

        // The font used for the sender label in message center.
        XCTAssertEqual(UIFont.apptentiveSenderLabel, .preferredFont(forTextStyle: .caption2))

        // The font used for the message date label in message center.
        XCTAssertEqual(UIFont.apptentiveMessageDateLabel, .preferredFont(forTextStyle: .caption2))

        // The font used for the instructions label for surveys.
        XCTAssertEqual(UIFont.apptentiveInstructionsLabel, .preferredFont(forTextStyle: .footnote))

        // The font used for the survey introduction label.
        XCTAssertEqual(UIFont.apptentiveSurveyIntroductionLabel, .preferredFont(forTextStyle: .subheadline))

        // The font used for the survey footer label (Thank You text).
        XCTAssertEqual(UIFont.apptentiveSubmitStatusLabel, .preferredFont(forTextStyle: .headline))

        // The font used for the disclaimer text.
        XCTAssertEqual(UIFont.apptentiveDisclaimerLabel, .preferredFont(forTextStyle: .callout))

        // The font used for the submit button at the end of surveys.
        XCTAssertEqual(UIFont.apptentiveSubmitButtonTitle, .preferredFont(forTextStyle: .headline))

        // The font used for the multi- and single-line text inputs in surveys.
        XCTAssertEqual(UIFont.apptentiveTextInput, .preferredFont(forTextStyle: .body))
    }
}
