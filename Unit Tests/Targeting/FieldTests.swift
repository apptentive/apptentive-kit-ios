//
//  FieldTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 8/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest
@testable import ApptentiveKit

class FieldTests: XCTestCase {
    func testRootField() {
        let field: Field = "application/cf_bundle_short_version_string"

        XCTAssertEqual(field.fullPath, "application/cf_bundle_short_version_string")
        XCTAssertEqual(field.keys.first, "application")
        XCTAssertEqual(field.position, 0)
        XCTAssertEqual(field.parentKeys, [])
    }

    func testChildField() throws {
        let field: Field = "application/cf_bundle_short_version_string/foo"

        let childField = try field.nextComponent()

        XCTAssertEqual(childField.fullPath, "application/cf_bundle_short_version_string/foo")
        XCTAssertEqual(childField.keys.first, "cf_bundle_short_version_string")
        XCTAssertEqual(childField.position, 1)
        XCTAssertEqual(childField.parentKeys, ["application"])

        let grandchildField = try childField.nextComponent()

        XCTAssertEqual(grandchildField.fullPath, "application/cf_bundle_short_version_string/foo")
        XCTAssertEqual(grandchildField.keys.first, "foo")
        XCTAssertEqual(grandchildField.position, 2)
        XCTAssertEqual(grandchildField.parentKeys, ["cf_bundle_short_version_string", "application"])

    }
}
