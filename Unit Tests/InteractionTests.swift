//
//  InteractionTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class InteractionTests: XCTestCase {
    func testDecodingInteraction() throws {
        guard let surveyURL = Bundle(for: type(of: self)).url(forResource: "Survey - 3.1", withExtension: "json") else {
            return XCTFail("Unable to find test survey data")
        }

        let surveyData = try Data(contentsOf: surveyURL)

        let _ = try JSONDecoder().decode(Interaction.self, from: surveyData)
    }
}
