//
//  NavigateToLinkControllerTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 12/2/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor struct NavigateToLinkControllerTests {
    var controller: NavigateToLinkController?
    var spyInteractionDelegate: SpyInteractionDelegate?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    init() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "NavigateToLink")

        guard case let Interaction.InteractionConfiguration.navigateToLink(configuration) = interaction.configuration else {
            throw TestError(reason: "Unable to create view model")
        }

        self.spyInteractionDelegate = SpyInteractionDelegate()

        self.controller = NavigateToLinkController(configuration: configuration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate!)
    }

    @Test func testNavigateToLinkSuccess() async throws {
        let url = URL(string: "http://www.apptentive.com")!

        #expect(self.controller?.configuration.url == url)

        let _ = await self.controller?.navigateToLink()

        try await MainActor.run {
            #expect(self.spyInteractionDelegate?.engagedEvent?.codePointName == "com.apptentive#NavigateToLink#navigate")
            #expect(self.spyInteractionDelegate?.openedURL == url)

            let event = try #require(self.spyInteractionDelegate?.engagedEvent)
            guard case let .navigateToLink(result) = event.userInfo else {
                throw TestError(reason: "Unable to get event userInfo")
            }

            #expect(result.success)
            #expect(result.url == url)
        }
    }

    @Test func testNavigateToLinkFailure() async throws {
        let url = URL(string: "http://www.apptentive.com")!

        #expect(self.controller?.configuration.url == url)
        self.spyInteractionDelegate?.shouldURLOpeningSucceed = false

        let _ = await self.controller?.navigateToLink()

        try await MainActor.run {
            #expect(self.spyInteractionDelegate?.engagedEvent?.codePointName == "com.apptentive#NavigateToLink#navigate")
            #expect(self.spyInteractionDelegate?.openedURL == url)

            let event = try #require(self.spyInteractionDelegate?.engagedEvent)
            guard case let .navigateToLink(result) = event.userInfo else {
                throw TestError(reason: "Unable to get event userInfo")
            }

            #expect(result.success == false)
            #expect(result.url == url)
        }
    }
}
