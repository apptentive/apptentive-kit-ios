//
//  FieldTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 8/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing

@testable import ApptentiveKit

struct FieldTests {
    @Test func testRootField() {
        let field: Field = "application/cf_bundle_short_version_string"

        #expect(field.fullPath == "application/cf_bundle_short_version_string")
        #expect(field.keys.first == "application")
        #expect(field.position == 0)
        #expect(field.parentKeys == [])
    }

    @Test func testChildField() throws {
        let field: Field = "application/cf_bundle_short_version_string/foo"

        let childField = try field.nextComponent()

        #expect(childField.fullPath == "application/cf_bundle_short_version_string/foo")
        #expect(childField.keys.first == "cf_bundle_short_version_string")
        #expect(childField.position == 1)
        #expect(childField.parentKeys == ["application"])

        let grandchildField = try childField.nextComponent()

        #expect(grandchildField.fullPath == "application/cf_bundle_short_version_string/foo")
        #expect(grandchildField.keys.first == "foo")
        #expect(grandchildField.position == 2)
        #expect(grandchildField.parentKeys == ["cf_bundle_short_version_string", "application"])
    }
}
