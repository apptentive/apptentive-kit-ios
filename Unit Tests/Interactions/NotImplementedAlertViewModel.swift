//
//  NotImplementedAlertViewModel.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 12/8/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class NotImplementedAlertViewModelTests: XCTestCase {

    var viewModel: NotImplementedAlertViewModel?
    var interaction: Interaction?

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "FakeInteraction")
        self.interaction = interaction
        XCTAssertTrue(interaction.typeName == "FakeInteraction")
        self.viewModel = NotImplementedAlertViewModel(interactionTypeName: interaction.typeName)
    }

    func testAlertView() {
        guard let viewModel = self.viewModel else { return XCTFail("Unable to load view model") }
        guard let interaction = self.interaction else {
            return XCTFail("Unable to load interaction")
        }
        XCTAssertEqual(viewModel.title, "Interaction Presenter Error")
        XCTAssertEqual(viewModel.message, "Interaction: '\(interaction.typeName)' is not implemented.")

    }

}
