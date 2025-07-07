//
//  TextModalViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor struct TextModalViewModelTests {
    var viewModel: DialogViewModel
    var spySender: SpyInteractionDelegate

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    init() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")

        guard case let Interaction.InteractionConfiguration.textModal(configuration) = interaction.configuration else {
            throw TestError(reason: "Unable to create view model")
        }

        self.spySender = SpyInteractionDelegate()
        self.viewModel = DialogViewModel(configuration: configuration, interaction: interaction, interactionDelegate: self.spySender)
    }

    @Test func testTextModal() {
        #expect(viewModel.title.flatMap { String($0.characters) } == "Message Title")
        #expect(viewModel.message.flatMap { String($0.characters) } == "Message content.")
        #expect(viewModel.actions[0].label == "Message Center")
        #expect(viewModel.actions[1].label == "Survey")
        #expect(viewModel.actions[2].label == "Link")
        #expect(viewModel.actions[3].label == "Dismiss")
        #expect(viewModel.dialogType == .textModal)
        #expect(viewModel.maxHeight == 100)
        #expect(viewModel.imageConfiguration?.url == URL(string: "https://variety.com/wp-content/uploads/2022/12/Disney-Plus.png")!)
        #expect(viewModel.imageConfiguration?.layout == "fill")
        #expect(viewModel.imageConfiguration?.altText == "Disney Logo")
        #expect(!viewModel.isTitleHidden)
        #expect(!viewModel.isMessageHidden)
        #expect(viewModel.image != DialogViewModel.Image.none)
    }

    @Test func testMessageCenterButton() async throws {
        viewModel.buttonSelected(at: 0)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        #expect(self.spySender.engagedEvent?.codePointName == "com.apptentive#TextModal#interaction")

        guard case .textModalAction(let textModalAction) = self.spySender.engagedEvent?.userInfo else {
            throw TestError(reason: "Expected event data of type textModalAction")
        }

        #expect(textModalAction.invokedInteractionID == "55c94045a71b52ea570054d6")
    }

    @Test func testSurveyButton() async throws {
        viewModel.buttonSelected(at: 1)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        guard case .textModalAction(let textModalAction) = self.spySender.engagedEvent?.userInfo else {
            throw TestError(reason: "Expected event data of type textModalAction")
        }

        #expect(textModalAction.invokedInteractionID == "55e6033045ce5551eb00000b")
    }

    @Test func testLinkButton() async throws {
        viewModel.buttonSelected(at: 2)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        guard case .textModalAction(let textModalAction) = self.spySender.engagedEvent?.userInfo else {
            throw TestError(reason: "Expected event data of type textModalAction")
        }

        #expect(textModalAction.invokedInteractionID == "56b248fac21f96e6700001d3")
    }

    @Test func testRecordedAnswer() async throws {
        viewModel.buttonSelected(at: 1)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        let recordedResponseValue = try #require(self.spySender.responses.values.first)
        let recordedAnswerValue = try #require(recordedResponseValue.first)
        #expect(recordedAnswerValue == Answer.choice("55e6037a45ce551189000017"))

        viewModel.buttonSelected(at: 2)

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        let recordedResponse2 = self.spySender.responses
        #expect(recordedResponse2[viewModel.interaction.id]?.count == 2)
        #expect(recordedResponse2[viewModel.interaction.id] == [Answer.choice("55e6037a45ce551189000017"), Answer.choice("55e6037a45ce551189000018")])
        #expect(self.spySender.lastResponse[self.viewModel.interaction.id] == [Answer.choice("55e6037a45ce551189000018")])
    }

    @Test func testDismissButton() {
        viewModel.buttonSelected(at: 3)

        #expect(self.spySender.engagedEvent?.codePointName == "com.apptentive#TextModal#dismiss")
    }

    @Test func testLaunch() {
        viewModel.launch()

        #expect(self.spySender.engagedEvent?.codePointName == "com.apptentive#TextModal#launch")
    }

    @Test func testImageProperties() async throws {
        guard case .loading(let altText, _) = viewModel.image else {
            throw TestError(reason: "Expected image to be loading after init.")
        }

        #expect(altText == "Disney Logo")

        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        self.spySender.prefetchedImage = UIImage(data: prefetchData)

        let _ = await self.viewModel.prepareForPresentation()

        guard case .loaded(let image, let accessibilityLabel, let layout) = self.viewModel.image else {
            throw TestError(reason: "Expected image to be loaded after runloop.")
        }

        #expect(image == self.spySender.prefetchedImage)
        #expect(accessibilityLabel == "Disney Logo")
        #expect(layout.contentMode(for: UITraitCollection()) == .scaleAspectFit)
        #expect(layout.imageInset == .zero)

        let ltrTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(layoutDirection: .leftToRight)
        ])

        let rtlTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(layoutDirection: .rightToLeft)
        ])

        #expect(DialogViewModel.Image.Layout.leading.contentMode(for: ltrTraitCollection) == .left)
        #expect(DialogViewModel.Image.Layout.leading.contentMode(for: rtlTraitCollection) == .right)

        #expect(DialogViewModel.Image.Layout.trailing.contentMode(for: ltrTraitCollection) == .right)
        #expect(DialogViewModel.Image.Layout.trailing.contentMode(for: rtlTraitCollection) == .left)

        #expect(DialogViewModel.Image.Layout.center.contentMode(for: UITraitCollection()) == .center)
        #expect(DialogViewModel.Image.Layout.center.imageInset == UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
    }
}
