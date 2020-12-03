//
//  TextModalViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class TextModalViewModelTests: XCTestCase {
    var viewModel: TextModalViewModel?
    var spySender: SpySender?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")

        guard case let Interaction.InteractionConfiguration.textModal(configuration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.spySender = SpySender()
        self.viewModel = TextModalViewModel(configuration: configuration, interaction: interaction, sender: self.spySender!)
    }

    func testTextModal() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.title, "Message Title")
        XCTAssertEqual(viewModel.message, "Message content.")
        XCTAssertEqual(viewModel.buttons[0].title, "Message Center")
        XCTAssertEqual(viewModel.buttons[1].title, "Survey")
        XCTAssertEqual(viewModel.buttons[2].title, "Link")
        XCTAssertEqual(viewModel.buttons[3].title, "Dismiss")
    }

    func testMessageCenterButton() {
        viewModel?.buttons[0].action?()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#TextModal#button_55e6037a45ce551189000016")
    }

    func testSurveyButton() {
        viewModel?.buttons[1].action?()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#TextModal#button_55e6037a45ce551189000017")
    }

    func testLinkButton() {
        viewModel?.buttons[2].action?()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#TextModal#button_55e6037a45ce551189000018")
    }

    func testDismissButton() {
        viewModel?.buttons[3].action?()

        XCTAssertNil(self.spySender?.engagedEvent)
    }
}
