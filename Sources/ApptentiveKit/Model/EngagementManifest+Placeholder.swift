//
//  EngagementManifest+Placeholder.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/3/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

extension EngagementManifest {
    static let placeholder: Self = {
        let fallbackInteractionID = "message_center_fallback"

        let fallbackTitle = NSLocalizedString("MC Unavailable Title", tableName: nil, bundle: .apptentive, value: "Message Center is not Available", comment: "Title for note saying MC is unavailable")
        let fallbackMessage = NSLocalizedString("MC Unavailable Message", tableName: nil, bundle: .apptentive, value: "Make sure your device can access the internet and try again.", comment: "Message for note saying MC is unavailable")
        let fallbackButtonTitle = NSLocalizedString("MC Unavailable Dismiss Button", tableName: nil, bundle: .apptentive, value: "OK", comment: "Dismiss button title for note saying MC is unavailable")

        let configuration = TextModalConfiguration(title: fallbackTitle, name: nil, body: fallbackMessage, actions: [.init(id: "dismiss", label: fallbackButtonTitle, actionType: .dismiss, invocations: [])], image: nil)
        let fallbackInteraction = Interaction(id: fallbackInteractionID, configuration: .textModal(configuration), typeName: "TextModal", format: nil)
        let fallbackInvocation = Invocation(interactionID: fallbackInteractionID, criteria: ImplicitAndClause(subClauses: []))

        return EngagementManifest(interactions: [fallbackInteraction], targets: [Event.showMessageCenterFallback.codePointName: [fallbackInvocation]], prefetch: [], expiry: .distantPast)
    }()
}
