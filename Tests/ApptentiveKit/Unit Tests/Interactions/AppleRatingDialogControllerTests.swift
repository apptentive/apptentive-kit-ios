//
//  AppleRatingDialogControllerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class AppleRatingDialogControllerTests: XCTestCase {
    var controller: AppleRatingDialogController?
    var spySender: SpyInteractionDelegate?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "AppleRatingDialog")

        guard case Interaction.InteractionConfiguration.appleRatingDialog = interaction.configuration else {
            return XCTFail("Unable to create controller")
        }

        self.spySender = SpyInteractionDelegate()
        self.controller = AppleRatingDialogController(interaction: interaction, delegate: self.spySender!)
    }

    func testWasShown() {
        self.spySender?.shouldRequestReviewSucceed = true

        controller?.requestReview()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, Event.shown(from: controller!.interaction).codePointName)
    }

    func testWasNotShown() {
        self.spySender?.shouldRequestReviewSucceed = false

        controller?.requestReview()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, Event.notShown(from: controller!.interaction).codePointName)
    }
}
