//
//  EnjoymentDialogViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class EnjoymentDialogViewModelTests: XCTestCase {
    var viewModel: DialogViewModel?
    var spySender: SpyInteractionDelegate?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "EnjoymentDialog")

        guard case let Interaction.InteractionConfiguration.enjoymentDialog(configuration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.spySender = SpyInteractionDelegate()
        self.viewModel = DialogViewModel(configuration: configuration, interaction: interaction, interactionDelegate: self.spySender!)
    }

    func testEnjoymentDialog() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.title, "Do you love this app?")
        XCTAssertNil(viewModel.message)
        let yesButtonText = viewModel.actions[1].label
        let noButtonText = viewModel.actions[0].label
        XCTAssertEqual(noButtonText, "No")
        XCTAssertEqual(yesButtonText, "Yes")
        XCTAssertNil(viewModel.imageConfiguration)
    }

    func testYesButton() {
        viewModel?.buttonSelected(at: 1)

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#EnjoymentDialog#yes")
    }

    func testNoButton() {
        viewModel?.buttonSelected(at: 0)

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#EnjoymentDialog#no")
    }
}
