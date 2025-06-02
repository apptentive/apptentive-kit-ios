//
//  EntitlementsParsingTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/30/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

class BundleFinder {}

struct EntitlementsParsingTests {
    @Test func testEntitlementsParsing() throws {
        let proProURL = Bundle(for: BundleFinder.self).url(forResource: "ExampleProPro", withExtension: "mobileprovision")!
        let proProData = try Data(contentsOf: proProURL)
        let proProPlist = try ProvisioningProfileParser.getEntitlements(from: proProData)!

        #expect(proProPlist["aps-environment"] as? String == "production")
    }
}
