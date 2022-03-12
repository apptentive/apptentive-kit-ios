//
//  NavigateToLinkControllerTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 12/2/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class NavigateToLinkControllerTests: XCTestCase {
    var controller: NavigateToLinkController?
    var spyInteractionDelegate: SpyInteractionDelegate?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "NavigateToLink")

        guard case let Interaction.InteractionConfiguration.navigateToLink(configuration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.spyInteractionDelegate = SpyInteractionDelegate()

        self.controller = NavigateToLinkController(configuration: configuration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate!)
    }

    func testNavigateToLinkSuccess() {
        let url = URL(string: "http://www.apptentive.com")!

        XCTAssertEqual(self.controller?.configuration.url, url)

        self.controller?.navigateToLink()

        XCTAssertEqual(self.spyInteractionDelegate?.engagedEvent?.codePointName, "com.apptentive#NavigateToLink#navigate")
        XCTAssertEqual(self.spyInteractionDelegate?.openedURL, url)

        guard let event = self.spyInteractionDelegate?.engagedEvent, case let .navigateToLink(result) = event.userInfo else {
            return XCTFail("Unable to get event userInfo")
        }

        XCTAssertEqual(result.success, true)
        XCTAssertEqual(result.url, url)
    }

    func testNavigateToLinkFailure() {
        let url = URL(string: "http://www.apptentive.com")!

        XCTAssertEqual(self.controller?.configuration.url, url)
        self.spyInteractionDelegate?.shouldURLOpeningSucceed = false

        self.controller?.navigateToLink()

        XCTAssertEqual(self.spyInteractionDelegate?.engagedEvent?.codePointName, "com.apptentive#NavigateToLink#navigate")
        XCTAssertEqual(self.spyInteractionDelegate?.openedURL, url)

        guard let event = self.spyInteractionDelegate?.engagedEvent, case let .navigateToLink(result) = event.userInfo else {
            return XCTFail("Unable to get event userInfo")
        }

        XCTAssertEqual(result.success, false)
        XCTAssertEqual(result.url, url)
    }
}
