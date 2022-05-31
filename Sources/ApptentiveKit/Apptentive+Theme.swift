//
//  Apptentive+Theme.swift
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

        let bundle = Bundle.module
        guard let barTintColor = UIColor(named: "barTint", in: bundle, compatibleWith: nil),
            let barForegroundColor = UIColor(named: "barForeground", in: bundle, compatibleWith: nil),
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
            let surveyGreeting = UIColor(named: "surveyGreetingText", in: bundle, compatibleWith: nil),
            let surveyImageChoice = UIColor(named: "surveyImageChoice", in: bundle, compatibleWith: nil),
            let attachmentDeleteButton = UIColor(named: "attachmentDeleteButton", in: bundle, compatibleWith: nil),
            let error = UIColor(named: "apptentiveError", in: bundle, compatibleWith: nil),
            let textInputPlaceholder = UIColor(named: "textInputPlaceholder", in: bundle, compatibleWith: nil),
            let textInputBorderSelected = UIColor(named: "textInputBorderSelected", in: bundle, compatibleWith: nil),
            let rangeNotSelectedSegmentBackground = UIColor(named: "rangeNotSelectedSegmentBackground", in: bundle, compatibleWith: nil)
        else {
            apptentiveCriticalError("Unable to locate color asset(s).")
            return
        }

        if #available(iOS 13.0, *) {
            let segmentedControlTextAttributesOnLoad = [NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: .medium)] as [NSAttributedString.Key: Any]
            let segmentedControlTextAttributesWhenSelected = [NSAttributedString.Key.foregroundColor: barForegroundColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12.0, weight: .medium)] as [NSAttributedString.Key: Any]

            let segmentedControlAppearance = UISegmentedControl.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
            segmentedControlAppearance.setTitleTextAttributes(segmentedControlTextAttributesOnLoad, for: .normal)
            segmentedControlAppearance.setTitleTextAttributes(segmentedControlTextAttributesWhenSelected, for: .selected)
            segmentedControlAppearance.setBackgroundImage(image(with: rangeNotSelectedSegmentBackground), for: .normal, barMetrics: .default)
            segmentedControlAppearance.setBackgroundImage(image(with: surveyImageChoice), for: .selected, barMetrics: .default)
            segmentedControlAppearance.setDividerImage(image(with: apptentiveRangeControlBorder), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        }

        let barTitleTextAttributes = [NSAttributedString.Key.foregroundColor: barForegroundColor, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .title2)]

        ApptentiveNavigationController.preferredStatusBarStyle = .lightContent

        UIModalPresentationStyle.apptentive = .fullScreen

        let navigationBarAppearanceProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
        navigationBarAppearanceProxy.titleTextAttributes = barTitleTextAttributes

        let toolBarAppearanceProxy = UIToolbar.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])

        if #available(iOS 13.0, *) {
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
        } else {
            navigationBarAppearanceProxy.barTintColor = barTintColor
            navigationBarAppearanceProxy.isTranslucent = false

            toolBarAppearanceProxy.barTintColor = barTintColor
            toolBarAppearanceProxy.isTranslucent = false
        }

        UIToolbar.apptentiveMode = .alwaysShown

        let buttonTitleTextAttributes = [NSAttributedString.Key.foregroundColor: barForegroundColor, NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]

        let barButtonItemAppearance = UIBarButtonItem.appearance(whenContainedInInstancesOf: [ApptentiveNavigationController.self])
        barButtonItemAppearance.setTitleTextAttributes(buttonTitleTextAttributes, for: .normal)
        barButtonItemAppearance.tintColor = barForegroundColor

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

        UIColor.apptentiveInstructionsLabel = instructionsLabelColor
        UIColor.apptentiveImageNotSelected = imageNotSelectedColor
        UIColor.apptentiveTextInputBorder = textInputBorderColor
        UIColor.apptentiveTextInput = textInputColor
        UIColor.apptentiveChoiceLabel = choiceLabelColor
        UIColor.apptentiveGroupedBackground = apptentiveGroupPrimaryColor
        UIColor.apptentiveSecondaryGroupedBackground = apptentiveGroupSecondaryColor
        UIColor.apptentiveSeparator = apptentiveGroupPrimaryColor
        UIColor.apptentiveTextInputBackground = textInputBackgroundColor
        UIColor.apptentiveSubmitButton = buttonTintColor
        UIColor.apptentiveQuestionLabel = question
        UIColor.apptentiveMessageBubbleInbound = messageBubbleInboundColor
        UIColor.apptentiveMessageBubbleOutbound = messageBubbleOutboundColor
        UIColor.apptentiveMessageLabelOutbound = termsOfServiceColor
        UIColor.apptentiveMessageLabelInbound = messageLabelInboundColor
        UIColor.apptentiveMessageCenterTextInputBorder = messageTextInputBorderColor
        UIColor.apptentiveSurveyIntroduction = surveyGreeting
        UIColor.apptentiveImageSelected = surveyImageChoice
        UIColor.apptentiveMessageCenterBackground = apptentiveGroupPrimaryColor
        UIColor.apptentiveMessageCenterComposeBoxBackground = apptentiveGroupPrimaryColor
        UIColor.apptentiveMessageCenterGreetingTitle = surveyGreeting
        UIColor.apptentiveMessageCenterGreetingBody = question
        UIColor.apptentiveMessageCenterStatus = textInputColor
        UIColor.apptentiveMessageCenterTextInputBorder = textInputBorderColor
        UIColor.apptentiveMessageCenterTextInputBackground = textInputBackgroundColor
        UIColor.apptentiveMessageCenterTextInput = textInputColor
        UIColor.apptentiveMessageCenterAttachmentDeleteButton = attachmentDeleteButton
        UIColor.apptentiveError = error
        UIColor.apptentiveTextInputPlaceholder = textInputPlaceholder
        UIColor.apptentiveMessageCenterTextInputPlaceholder = textInputPlaceholder
        UIColor.apptentiveTextInputBorderSelected = textInputBorderSelected

        if #available(iOS 13.0, *) {
            UIColor.apptentiveRangeControlBorder = apptentiveRangeControlBorder
        } else {
            UIColor.apptentiveRangeControlBorder = .clear
        }

        UIColor.apptentiveTermsOfServiceLabel = termsOfServiceColor

        UIFont.apptentiveQuestionLabel = .preferredFont(forTextStyle: .body)
        UIFont.apptentiveChoiceLabel = .preferredFont(forTextStyle: .body)
        UIFont.apptentiveTextInput = .preferredFont(forTextStyle: .body)

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

    private func image(with color: UIColor?) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        if let cg = color?.cgColor {
            context?.setFillColor(cg)
        }
        context?.fill(rect)
        let theImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return theImage
    }
}
