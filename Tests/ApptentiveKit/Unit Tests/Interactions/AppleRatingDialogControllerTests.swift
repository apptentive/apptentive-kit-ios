//
//  AppleRatingDialogControllerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor struct AppleRatingDialogControllerTests {
    var controller: AppleRatingDialogController?
    var spySender: SpyInteractionDelegate?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    init() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "AppleRatingDialog")

        guard case Interaction.InteractionConfiguration.appleRatingDialog = interaction.configuration else {
            throw TestError(reason: "Wrong interaction configuration")
        }

        self.spySender = SpyInteractionDelegate()
        self.controller = AppleRatingDialogController(interaction: interaction, delegate: self.spySender!)
    }

    @Test func testWasShown() async throws {
        self.spySender?.shouldRequestReviewSucceed = true

        try await controller?.requestReview()

        #expect(self.spySender?.engagedEvent?.codePointName == Event.shown(from: controller!.interaction).codePointName)
    }

    @Test func testWasNotShown() async throws {
        self.spySender?.shouldRequestReviewSucceed = false

        try await controller?.requestReview()

        #expect(self.spySender?.engagedEvent?.codePointName == Event.notShown(from: controller!.interaction).codePointName)
    }
}
