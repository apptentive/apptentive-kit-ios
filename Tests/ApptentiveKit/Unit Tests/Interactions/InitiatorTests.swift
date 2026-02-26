//
//  InitiatorTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 8/6/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

@MainActor struct InitiatorTests {

    var spyInteractionDelegate: SpyInteractionDelegate?

    init() throws {
        self.spyInteractionDelegate = SpyInteractionDelegate()
    }

    @Test func testTriggerSuccess() {
        let interaction = try! InteractionTestHelpers.loadInteraction(named: "Initiator")

        self.spyInteractionDelegate?.engage(event: .launch(from: interaction))
        #expect(self.spyInteractionDelegate?.engagedEvent?.codePointName == "com.apptentive#Initiator#launch")
    }
}
