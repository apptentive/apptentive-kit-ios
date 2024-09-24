//
//  InitiatorTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 8/6/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import Foundation
import XCTest

@testable import ApptentiveKit

class InitiatorTests: XCTestCase {

    var spyInteractionDelegate: SpyInteractionDelegate?

    override func setUpWithError() throws {

        self.spyInteractionDelegate = SpyInteractionDelegate()
    }

    func testTriggerSuccess() {
        let interaction = try! InteractionTestHelpers.loadInteraction(named: "Initiator")

        self.spyInteractionDelegate?.engage(event: .launch(from: interaction))
        XCTAssertEqual(self.spyInteractionDelegate?.engagedEvent?.codePointName, "com.apptentive#Initiator#launch")
    }

}
