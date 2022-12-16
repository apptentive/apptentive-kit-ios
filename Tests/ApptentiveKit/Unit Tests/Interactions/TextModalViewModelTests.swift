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
    var viewModel: TextModalViewModel!
    var spySender: SpyInteractionDelegate!

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")

        guard case let Interaction.InteractionConfiguration.textModal(configuration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.spySender = SpyInteractionDelegate()
        self.viewModel = TextModalViewModel(configuration: configuration, interaction: interaction, interactionDelegate: self.spySender!)
    }

    func testTextModal() {
        XCTAssertEqual(viewModel.title, "Message Title")
        XCTAssertEqual(viewModel.message, "Message content.")
        XCTAssertEqual(viewModel.buttons[0].title, "Message Center")
        XCTAssertEqual(viewModel.buttons[1].title, "Survey")
        XCTAssertEqual(viewModel.buttons[2].title, "Link")
        XCTAssertEqual(viewModel.buttons[3].title, "Dismiss")
    }

    func testMessageCenterButton() {
        viewModel.buttons[0].action?()

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#interaction")
        switch self.spySender.engagedEvent?.userInfo {
        case .textModalAction(let textModalAction):
            XCTAssertEqual(textModalAction.invokedInteractionID, "55c94045a71b52ea570054d6")

        default:
            XCTFail("Expected event data of type textModalAction")
        }
    }

    func testSurveyButton() {
        viewModel.buttons[1].action?()

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#interaction")
        switch self.spySender.engagedEvent?.userInfo {
        case .textModalAction(let textModalAction):
            XCTAssertEqual(textModalAction.invokedInteractionID, "55e6033045ce5551eb00000b")

        default:
            XCTFail("Expected event data of type textModalAction")
        }
    }

    func testLinkButton() {
        viewModel.buttons[2].action?()

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#interaction")
        switch self.spySender.engagedEvent?.userInfo {
        case .textModalAction(let textModalAction):
            XCTAssertEqual(textModalAction.invokedInteractionID, "56b248fac21f96e6700001d3")

        default:
            XCTFail("Expected event data of type textModalAction")
        }
    }

    func testRecordedAnswer() {
        self.spySender.recordResponse(.answered([.choice("abc123")]), for: self.viewModel.interaction.id)
        self.viewModel.launch()

        XCTAssertNil(self.spySender.lastResponse[self.viewModel.interaction.id])

        viewModel.buttons[1].action?()
        let recordedResponse = self.spySender.responses
        XCTAssertEqual(recordedResponse[viewModel.interaction.id]?.count, 2)
        XCTAssertEqual(recordedResponse[viewModel.interaction.id], [Answer.choice("abc123"), Answer.choice("55e6037a45ce551189000017")])

        XCTAssertEqual(self.spySender.lastResponse[self.viewModel.interaction.id], [Answer.choice("55e6037a45ce551189000017")])
    }

    func testDismissButton() {
        viewModel.buttons[3].action?()

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#dismiss")
    }

    func testLaunch() {
    }
}
