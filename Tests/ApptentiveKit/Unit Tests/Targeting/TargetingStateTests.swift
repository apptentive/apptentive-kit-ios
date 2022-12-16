//
//  TargetingStateTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

// Write tests based on https://apptentive.atlassian.net/wiki/spaces/APPTENTIVE/pages/107282439/Criteria+V7+Specification

class TargetingStateTests: XCTestCase {
    var conversation: Conversation!

    override func setUp() {
        self.conversation = Conversation(environment: MockEnvironment())
    }

    func testApplicationVersion() throws {
        XCTAssertEqual(try self.conversation.value(for: "application/cf_bundle_short_version_string") as? Version, Version(string: "0.0.0"))

        self.conversation.appRelease.version = "1.2.3"

        XCTAssertEqual(try self.conversation.value(for: "application/cf_bundle_short_version_string") as? Version, Version(string: "1.2.3"))
    }

    func testApplicationBuild() throws {
        XCTAssertEqual(try self.conversation.value(for: "application/cf_bundle_version") as? Version, Version(string: "1"))

        self.conversation.appRelease.build = "4.5.6"

        XCTAssertEqual(try self.conversation.value(for: "application/cf_bundle_version") as? Version, Version(string: "4.5.6"))
    }

    func testDebugBuild() throws {
        XCTAssertEqual(try self.conversation.value(for: "application/debug") as? Bool, true)

        self.conversation.appRelease.isDebugBuild = false

        XCTAssertEqual(try self.conversation.value(for: "application/debug") as? Bool, false)
    }

    func testSDKVersion() throws {
        self.conversation.appRelease.sdkVersion = "7.8.9"

        XCTAssertEqual(try self.conversation.value(for: "sdk/version") as? Version, Version(string: "7.8.9"))
    }

    func testCurrentTime() throws {
        guard let conversationCurrentTime = try self.conversation.value(for: "current_time") as? Date else {
            return XCTFail("Can't get date from conversation's current_time")
        }

        XCTAssertEqual(conversationCurrentTime.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1)
    }

    func testIsUpdatedVersion() throws {
        XCTAssertEqual(try self.conversation.value(for: "is_update/cf_bundle_short_version_string") as? Bool, false)

        self.conversation.appRelease.bumpVersion()

        XCTAssertEqual(try self.conversation.value(for: "is_update/cf_bundle_short_version_string") as? Bool, true)
    }

    func testIsUpdatedBuild() throws {
        XCTAssertEqual(try self.conversation.value(for: "is_update/cf_bundle_version") as? Bool, false)

        self.conversation.appRelease.bumpBuild()

        XCTAssertEqual(try self.conversation.value(for: "is_update/cf_bundle_version") as? Bool, true)
    }

    func testInstallTime() throws {
        guard let installTime = try self.conversation.value(for: "time_at_install/total") as? Date else {
            return XCTFail("Can't get date from conversation's time_at_install/total")
        }

        XCTAssertEqual(installTime.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1)
    }

    func testVersionInstallTime() throws {
        guard let installTime = try self.conversation.value(for: "time_at_install/cf_bundle_short_version_string") as? Date else {
            return XCTFail("Can't get date from conversation's time_at_install/cf_bundle_short_version_string")
        }

        XCTAssertEqual(installTime.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1)
    }

    func testBuildInstallTime() throws {
        guard let installTime = try self.conversation.value(for: "time_at_install/cf_bundle_version") as? Date else {
            return XCTFail("Can't get date from conversation's time_at_install/cf_bundle_version")
        }

        XCTAssertEqual(installTime.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1)
    }

    func testExistingCodePoint() throws {
        self.conversation.codePoints.invoke(for: "local#app#test")

        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#test/invokes/total") as? Int, 1)
        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_version") as? Int, 1)
        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_short_version_string") as? Int, 1)

        guard let lastInvoked = try self.conversation.value(for: "code_point/local#app#test/last_invoked_at") as? Date else {
            return XCTFail("Can't get date from conversation's code_point/local#app#test/last_invoked_at")
        }

        XCTAssertEqual(lastInvoked.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1)

        self.conversation.codePoints.resetBuild()
        self.conversation.codePoints.resetVersion()

        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_version") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_short_version_string") as? Int, 0)
    }

    func testUnseenCodePoint() throws {
        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#unseen/invokes/total") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#unseen/invokes/cf_bundle_version") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "code_point/local#app#unseen/invokes/cf_bundle_short_version_string") as? Int, 0)
        XCTAssertNil(try self.conversation.value(for: "code_point/local#app#unseen/last_invoked_at"))
    }

    func testExistingInteraction() throws {
        self.conversation.interactions.record(
            .answered([.choice("abc123"), .freeform("hey"), .other("def456", "you"), .range(-2)]),
            for: "abc123")

        self.conversation.interactions.resetCurrentResponse(for: "abc123")

        XCTAssertNil(try self.conversation.value(for: "interactions/abc123/current_answer/value"))
        XCTAssertNil(try self.conversation.value(for: "interactions/abc123/current_answer/id"))

        self.conversation.interactions.record(
            .answered([.choice("abc123"), .freeform("hey"), .other("def456", "you"), .range(-2)]),
            for: "abc123")

        XCTAssertEqual(try self.conversation.value(for: "interactions/abc123/invokes/total") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_version") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_short_version_string") as? Int, 0)
        XCTAssertEqual(
            try self.conversation.value(for: "interactions/abc123/answers/value") as? Set<Answer.Value>,
            Set([.string("hey"), .string("you"), .int(-2)]))
        XCTAssertEqual(
            try self.conversation.value(for: "interactions/abc123/answers/id") as? Set<String>,
            Set(["abc123", "def456"]))

        if try self.conversation.value(for: "interactions/abc123/last_invoked_at") != nil {
            return XCTFail("interactions/abc123/last_invoked_at should be nil")
        }

        self.conversation.interactions.resetBuild()
        self.conversation.interactions.resetVersion()

        XCTAssertEqual(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_version") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_short_version_string") as? Int, 0)
    }

    func testUnseenInteraction() throws {
        XCTAssertEqual(try self.conversation.value(for: "interactions/unseen123/invokes/total") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "interactions/unseen123/invokes/cf_bundle_version") as? Int, 0)
        XCTAssertEqual(try self.conversation.value(for: "interactions/unseen123/invokes/cf_bundle_short_version_string") as? Int, 0)
        XCTAssertNil(try self.conversation.value(for: "interactions/unseen123/last_invoked_at"))
        XCTAssertNil(try self.conversation.value(for: "interactions/unseen123/answers/value"))
        XCTAssertNil(try self.conversation.value(for: "interactions/unseen123/answers/id"))
        XCTAssertNil(try self.conversation.value(for: "interactions/unseen123/current_answer/value"))
        XCTAssertNil(try self.conversation.value(for: "interactions/unseen123/current_answer/id"))
    }

    func testPersonName() throws {
        XCTAssertNil(try self.conversation.value(for: "person/name"))

        self.conversation.person.name = "Testy McTesterson"

        XCTAssertEqual(try self.conversation.value(for: "person/name") as? String, "Testy McTesterson")
    }

    func testPersonEmail() throws {
        XCTAssertNil(try self.conversation.value(for: "person/email"))

        self.conversation.person.emailAddress = "test@example.com"

        XCTAssertEqual(try self.conversation.value(for: "person/email") as? String, "test@example.com")
    }

    func testPersonCustomData() throws {
        XCTAssertNil(try self.conversation.value(for: "person/custom_data/string"))
        XCTAssertNil(try self.conversation.value(for: "person/custom_data/number"))
        XCTAssertNil(try self.conversation.value(for: "person/custom_data/boolean"))

        self.conversation.person.customData["string"] = "string"
        self.conversation.person.customData["number"] = 5
        self.conversation.person.customData["boolean"] = true

        XCTAssertEqual(try self.conversation.value(for: "person/custom_data/string") as? String, "string")
        XCTAssertEqual(try self.conversation.value(for: "person/custom_data/number") as? Int, 5)
        XCTAssertEqual(try self.conversation.value(for: "person/custom_data/boolean") as? Bool, true)
    }

    func testDeviceOSName() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/os_name") as? String, "iOS")
    }

    func testDeviceOSVersion() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/os_version") as? Version, "12")
    }

    func testDeviceOSBuild() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/os_build") as? Version, "1")
    }

    func testDeviceHardware() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/hardware") as? String, "iPhone0,0")
    }

    func testDeviceUUID() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/uuid") as? UUID, self.conversation.device.uuid)
    }

    func testDeviceCarrier() throws {
        self.conversation.device.carrier = "foo"

        XCTAssertEqual(try self.conversation.value(for: "device/carrier") as? String, "foo")
    }

    func testDeviceLocaleCountryCode() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/locale_country_code") as? String, "US")
    }

    func testDeviceLocaleLanguageCode() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/locale_language_code") as? String, "en")
    }

    func testDeviceLocaleRaw() throws {
        XCTAssertEqual(try self.conversation.value(for: "device/locale_raw") as? String, "en_US")
    }

    func testDeviceCustomData() throws {
        XCTAssertNil(try self.conversation.value(for: "device/custom_data/string"))
        XCTAssertNil(try self.conversation.value(for: "device/custom_data/number"))
        XCTAssertNil(try self.conversation.value(for: "device/custom_data/boolean"))

        self.conversation.device.customData["string"] = "string"
        self.conversation.device.customData["number"] = 5
        self.conversation.device.customData["boolean"] = true

        XCTAssertEqual(try self.conversation.value(for: "device/custom_data/string") as? String, "string")
        XCTAssertEqual(try self.conversation.value(for: "device/custom_data/number") as? Int, 5)
        XCTAssertEqual(try self.conversation.value(for: "device/custom_data/boolean") as? Bool, true)
    }

    func testRandomPercent() throws {
        XCTAssertEqual(try self.conversation.value(for: "random/percent") as? Double, 50)
        XCTAssertEqual(try self.conversation.value(for: "random/xyz/percent") as? Double, 50)

        XCTAssertEqual(self.conversation.random.values["xyz"], 0.5)
    }
}
