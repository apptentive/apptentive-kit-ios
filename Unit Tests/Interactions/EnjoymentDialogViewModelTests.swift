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
    var viewModel: EnjoymentDialogViewModel?
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
        self.viewModel = EnjoymentDialogViewModel(configuration: configuration, interaction: interaction, delegate: self.spySender!)
    }

    func testEnjoymentDialog() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.title, "Do you love this app?")
        XCTAssertNil(viewModel.message)
        XCTAssertEqual(viewModel.buttons[0].title, "Yes")
        XCTAssertEqual(viewModel.buttons[1].title, "No")
    }

    func testYesButton() {
        viewModel?.buttons[0].action?()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#EnjoymentDialog#yes")
    }

    func testNoButton() {
        viewModel?.buttons[1].action?()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#EnjoymentDialog#no")
    }
}
