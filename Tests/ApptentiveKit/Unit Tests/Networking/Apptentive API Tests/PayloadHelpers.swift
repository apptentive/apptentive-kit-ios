//
//  PayloadHelpers.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/21/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import GenericJSON
import XCTest

@testable import ApptentiveKit

func checkPayloadEquivalence(between jsonObject: Payload.JSONObject, and expectedJSON: String, comparisons: [String]) throws {
    var actualJSON = try JSON(encodable: jsonObject)
    var expectedJSON = try JSON(JSONSerialization.jsonObject(with: expectedJSON.data(using: .utf8)!))

    if !jsonObject.shouldStripContainer {
        let containerName = jsonObject.specializedJSONObject.containerKey.rawValue
        actualJSON = actualJSON[containerName]!
        expectedJSON = expectedJSON[containerName]!
    }

    XCTAssertNotNil(actualJSON["nonce"])
    XCTAssertNotNil(expectedJSON["nonce"])

    XCTAssertGreaterThan(Date(timeIntervalSinceReferenceDate: actualJSON["client_created_at"]!.doubleValue!), Date(timeIntervalSince1970: 1_600_904_569))
    XCTAssertEqual(Date(timeIntervalSince1970: expectedJSON["client_created_at"]!.doubleValue!), Date(timeIntervalSince1970: 1_600_904_569))

    XCTAssertNotNil(actualJSON["client_created_at_utc_offset"])
    XCTAssertNotNil(expectedJSON["client_created_at_utc_offset"])

    for comparison in comparisons {
        XCTAssertEqual(actualJSON[comparison], expectedJSON[comparison])
    }
}
