//
//  AppleRatingDialogController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import StoreKit
import UIKit

typealias AppleRatingDialogInteractionDelegate = EventEngaging & ReviewRequesting

@MainActor final class AppleRatingDialogController {
    let interaction: Interaction
    let delegate: AppleRatingDialogInteractionDelegate

    private var didShowReviewController = false
    private let reviewWindowTimeout = 1

    init(interaction: Interaction, delegate: AppleRatingDialogInteractionDelegate) {
        self.interaction = interaction
        self.delegate = delegate
    }

    func requestReview() async throws {
        self.delegate.engage(event: .request(from: self.interaction))
        let wasShown = try await self.delegate.requestReview()

        if wasShown {
            self.delegate.engage(event: .shown(from: self.interaction))
        } else {
            self.delegate.engage(event: .notShown(from: self.interaction))
        }
    }
}

extension Event {
    static func request(from interaction: Interaction) -> Event {
        Self(internalName: "request", interaction: interaction)
    }

    static func shown(from interaction: Interaction) -> Event {
        Self(internalName: "shown", interaction: interaction)
    }

    static func notShown(from interaction: Interaction) -> Event {
        Self(internalName: "not_shown", interaction: interaction)
    }
}
