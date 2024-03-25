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
    var viewModel: DialogViewModel!
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
        self.viewModel = DialogViewModel(configuration: configuration, interaction: interaction, interactionDelegate: self.spySender!)
    }

    func testTextModal() {
        XCTAssertEqual(viewModel.title,"Message Title")
        XCTAssertEqual(viewModel.message, "Message content.")
        XCTAssertEqual(viewModel.actions[0].label, "Message Center")
        XCTAssertEqual(viewModel.actions[1].label, "Survey")
        XCTAssertEqual(viewModel.actions[2].label, "Link")
        XCTAssertEqual(viewModel.actions[3].label, "Dismiss")
    }

    func testMessageCenterButton() {
        viewModel?.buttonSelected(at: 0)

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#interaction")
        switch self.spySender.engagedEvent?.userInfo {
        case .textModalAction(let textModalAction):
            XCTAssertEqual(textModalAction.invokedInteractionID, "55c94045a71b52ea570054d6")

        default:
            XCTFail("Expected event data of type textModalAction")
        }
    }

    func testSurveyButton() {
        viewModel?.buttonSelected(at: 1)

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#interaction")
        switch self.spySender.engagedEvent?.userInfo {
        case .textModalAction(let textModalAction):
            XCTAssertEqual(textModalAction.invokedInteractionID, "55e6033045ce5551eb00000b")

        default:
            XCTFail("Expected event data of type textModalAction")
        }
    }

    func testLinkButton() {
        viewModel?.buttonSelected(at: 2)

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#interaction")
        switch self.spySender.engagedEvent?.userInfo {
        case .textModalAction(let textModalAction):
            XCTAssertEqual(textModalAction.invokedInteractionID, "56b248fac21f96e6700001d3")

        default:
            XCTFail("Expected event data of type textModalAction")
        }
    }

    func testRecordedAnswer() {
        viewModel?.buttonSelected(at: 1)
        let recordedResponse = self.spySender?.responses
        XCTAssertEqual(recordedResponse?.count, 1)
        if let recordedResponseValue = recordedResponse?.values.first, let recordedAnswerValue = recordedResponseValue.first {
            XCTAssertEqual(recordedAnswerValue, Answer.choice("55e6037a45ce551189000017"))
        }

        viewModel?.buttonSelected(at: 2)
        let recordedResponse2 = self.spySender.responses
        XCTAssertEqual(recordedResponse2[viewModel.interaction.id]?.count, 2)
        XCTAssertEqual(recordedResponse2[viewModel.interaction.id], [Answer.choice("55e6037a45ce551189000017"), Answer.choice("55e6037a45ce551189000018")])

        XCTAssertEqual(self.spySender.lastResponse[self.viewModel.interaction.id], [Answer.choice("55e6037a45ce551189000018")])
    }

    func testDismissButton() {
        viewModel?.buttonSelected(at: 3)

        XCTAssertEqual(self.spySender.engagedEvent?.codePointName, "com.apptentive#TextModal#dismiss")
    }

    func testLaunch() {
        viewModel.launch()

        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#TextModal#launch")
    }

    func testImageProperties() {

        guard case .loading(let altText, _) = viewModel.image else {
            return XCTFail("Expected image to be loading after init.")
        }

        XCTAssertEqual(altText, "Disney Logo")

        let expectation = self.expectation(description: "Wait for image to load")

        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        self.spySender.prefetchedImage = UIImage(data: prefetchData)

        self.viewModel.prepareForPresentation {
            guard case .loaded = self.viewModel.image else {
                return XCTFail("Expected image to be loaded after runloop.")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1)
    }
}
