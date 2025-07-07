//
//  EnjoymentDialogViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor struct EnjoymentDialogViewModelTests {
    var viewModel: DialogViewModel
    var spySender: SpyInteractionDelegate

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    init() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "EnjoymentDialog")

        guard case let Interaction.InteractionConfiguration.enjoymentDialog(configuration) = interaction.configuration else {
            throw TestError(reason: "Unable to create view model")
        }

        self.spySender = SpyInteractionDelegate()
        self.viewModel = DialogViewModel(configuration: configuration, interaction: interaction, interactionDelegate: self.spySender)
    }

    @Test func testEnjoymentDialog() {
        #expect(self.viewModel.title.flatMap { String($0.characters) } == "Do you love this app?")
        #expect(self.viewModel.message == nil)
        let yesButtonText = self.viewModel.actions[1].label
        let noButtonText = self.viewModel.actions[0].label
        #expect(noButtonText == "No")
        #expect(yesButtonText == "Yes")
        #expect(self.viewModel.imageConfiguration == nil)
    }

    @Test func testYesButton() {
        self.viewModel.buttonSelected(at: 1)

        #expect(self.spySender.engagedEvent?.codePointName == "com.apptentive#EnjoymentDialog#yes")
    }

    @Test func testNoButton() {
        self.viewModel.buttonSelected(at: 0)

        #expect(self.spySender.engagedEvent?.codePointName == "com.apptentive#EnjoymentDialog#no")
    }
}
