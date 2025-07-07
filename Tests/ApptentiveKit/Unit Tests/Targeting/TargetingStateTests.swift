//
//  TargetingStateTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

// Write tests based on https://apptentive.atlassian.net/wiki/spaces/APPTENTIVE/pages/107282439/Criteria+V7+Specification

class TargetingStateTests {
    var conversation: Conversation!

    init() {
        self.conversation = Conversation(dataProvider: MockDataProvider())
    }

    @Test func testApplicationVersion() throws {
        #expect(try self.conversation.value(for: "application/cf_bundle_short_version_string") as? Version == Version(string: "0.0.0"))

        self.conversation.appRelease.version = "1.2.3"

        #expect(try self.conversation.value(for: "application/cf_bundle_short_version_string") as? Version == Version(string: "1.2.3"))
    }

    @Test func testApplicationBuild() throws {
        #expect(try self.conversation.value(for: "application/cf_bundle_version") as? Version == Version(string: "1"))

        self.conversation.appRelease.build = "4.5.6"

        #expect(try self.conversation.value(for: "application/cf_bundle_version") as? Version == Version(string: "4.5.6"))
    }

    @Test func testDebugBuild() throws {
        #expect(try self.conversation.value(for: "application/debug") as? Bool == true)

        self.conversation.appRelease.isDebugBuild = false

        #expect(try self.conversation.value(for: "application/debug") as? Bool == false)
    }

    @Test func testSDKVersion() throws {
        self.conversation.appRelease.sdkVersion = "7.8.9"

        #expect(try self.conversation.value(for: "sdk/version") as? Version == Version(string: "7.8.9"))
    }

    @Test func testCurrentTime() throws {
        guard let conversationCurrentTime = try self.conversation.value(for: "current_time") as? Date else {
            throw TestError(reason: "Can't get date from conversation's current_time")
        }

        #expect((conversationCurrentTime.timeIntervalSince1970 == Date().timeIntervalSince1970) ± 1)
    }

    @Test func testIsUpdatedVersion() throws {
        #expect(try self.conversation.value(for: "is_update/cf_bundle_short_version_string") as? Bool == false)

        self.conversation.appRelease.bumpVersion()

        #expect(try self.conversation.value(for: "is_update/cf_bundle_short_version_string") as? Bool == true)
    }

    @Test func testIsUpdatedBuild() throws {
        #expect(try self.conversation.value(for: "is_update/cf_bundle_version") as? Bool == false)

        self.conversation.appRelease.bumpBuild()

        #expect(try self.conversation.value(for: "is_update/cf_bundle_version") as? Bool == true)
    }

    @Test func testInstallTime() throws {
        guard let installTime = try self.conversation.value(for: "time_at_install/total") as? Date else {
            throw TestError(reason: "Can't get date from conversation's time_at_install/total")
        }

        #expect((installTime.timeIntervalSince1970 == Date().timeIntervalSince1970) ± 1)
    }

    @Test func testVersionInstallTime() throws {
        guard let installTime = try self.conversation.value(for: "time_at_install/cf_bundle_short_version_string") as? Date else {
            throw TestError(reason: "Can't get date from conversation's time_at_install/cf_bundle_short_version_string")
        }

        #expect((installTime.timeIntervalSince1970 == Date().timeIntervalSince1970) ± 1)
    }

    @Test func testBuildInstallTime() throws {
        guard let installTime = try self.conversation.value(for: "time_at_install/cf_bundle_version") as? Date else {
            throw TestError(reason: "Can't get date from conversation's time_at_install/cf_bundle_version")
        }

        #expect((installTime.timeIntervalSince1970 == Date().timeIntervalSince1970) ± 1)
    }

    @Test func testExistingCodePoint() throws {
        self.conversation.codePoints.increment(for: "local#app#test")

        #expect(try self.conversation.value(for: "code_point/local#app#test/invokes/total") as? Int == 1)
        #expect(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_version") as? Int == 1)
        #expect(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_short_version_string") as? Int == 1)

        guard let lastInvoked = try self.conversation.value(for: "code_point/local#app#test/last_invoked_at") as? Date else {
            throw TestError(reason: "Can't get date from conversation's code_point/local#app#test/last_invoked_at")
        }

        #expect((lastInvoked.timeIntervalSince1970 == Date().timeIntervalSince1970) ± 1)

        self.conversation.codePoints.resetBuild()
        self.conversation.codePoints.resetVersion()

        #expect(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_version") as? Int == 0)
        #expect(try self.conversation.value(for: "code_point/local#app#test/invokes/cf_bundle_short_version_string") as? Int == 0)
    }

    @Test func testUnseenCodePoint() throws {
        #expect(try self.conversation.value(for: "code_point/local#app#unseen/invokes/total") as? Int == 0)
        #expect(try self.conversation.value(for: "code_point/local#app#unseen/invokes/cf_bundle_version") as? Int == 0)
        #expect(try self.conversation.value(for: "code_point/local#app#unseen/invokes/cf_bundle_short_version_string") as? Int == 0)
        #expect(try self.conversation.value(for: "code_point/local#app#unseen/last_invoked_at") == nil)
    }

    @Test func testExistingInteraction() throws {
        self.conversation.interactions.record(
            .answered([.choice("abc123"), .freeform("hey"), .other("def456", "you"), .range(-2)]),
            for: "abc123")

        self.conversation.interactions.resetCurrentResponse(for: "abc123")

        #expect(try self.conversation.value(for: "interactions/abc123/current_answer/value") == nil)
        #expect(try self.conversation.value(for: "interactions/abc123/current_answer/id") == nil)

        self.conversation.interactions.record(
            .answered([.choice("abc123"), .freeform("hey"), .other("def456", "you"), .range(-2)]),
            for: "abc123")

        #expect(try self.conversation.value(for: "interactions/abc123/invokes/total") as? Int == 0)
        #expect(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_version") as? Int == 0)
        #expect(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_short_version_string") as? Int == 0)
        #expect(
            try self.conversation.value(for: "interactions/abc123/answers/value") as? Set<Answer.Value> == Set([.string("hey"), .string("you"), .int(-2)]))
        #expect(
            try self.conversation.value(for: "interactions/abc123/answers/id") as? Set<String> == Set(["abc123", "def456"]))

        if try self.conversation.value(for: "interactions/abc123/last_invoked_at") != nil {
            throw TestError(reason: "interactions/abc123/last_invoked_at should be nil")
        }

        self.conversation.interactions.resetBuild()
        self.conversation.interactions.resetVersion()

        #expect(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_version") as? Int == 0)
        #expect(try self.conversation.value(for: "interactions/abc123/invokes/cf_bundle_short_version_string") as? Int == 0)
    }

    @Test func testUnseenInteraction() throws {
        #expect(try self.conversation.value(for: "interactions/unseen123/invokes/total") as? Int == 0)
        #expect(try self.conversation.value(for: "interactions/unseen123/invokes/cf_bundle_version") as? Int == 0)
        #expect(try self.conversation.value(for: "interactions/unseen123/invokes/cf_bundle_short_version_string") as? Int == 0)
        #expect(try self.conversation.value(for: "interactions/unseen123/last_invoked_at") == nil)
        #expect(try self.conversation.value(for: "interactions/unseen123/answers/value") == nil)
        #expect(try self.conversation.value(for: "interactions/unseen123/answers/id") == nil)
        #expect(try self.conversation.value(for: "interactions/unseen123/current_answer/value") == nil)
        #expect(try self.conversation.value(for: "interactions/unseen123/current_answer/id") == nil)
    }

    @Test func testPersonName() throws {
        #expect(try self.conversation.value(for: "person/name") == nil)

        self.conversation.person.name = "Testy McTesterson"

        #expect(try self.conversation.value(for: "person/name") as? String == "Testy McTesterson")
    }

    @Test func testPersonEmail() throws {
        #expect(try self.conversation.value(for: "person/email") == nil)

        self.conversation.person.emailAddress = "test@example.com"

        #expect(try self.conversation.value(for: "person/email") as? String == "test@example.com")
    }

    @Test func testPersonCustomData() throws {
        #expect(try self.conversation.value(for: "person/custom_data/string") == nil)
        #expect(try self.conversation.value(for: "person/custom_data/number") == nil)
        #expect(try self.conversation.value(for: "person/custom_data/boolean") == nil)

        self.conversation.person.customData["string"] = "string"
        self.conversation.person.customData["number"] = 5
        self.conversation.person.customData["boolean"] = true

        #expect(try self.conversation.value(for: "person/custom_data/string") as? String == "string")
        #expect(try self.conversation.value(for: "person/custom_data/number") as? Int == 5)
        #expect(try self.conversation.value(for: "person/custom_data/boolean") as? Bool == true)
    }

    @Test func testDeviceOSName() throws {
        #expect(try self.conversation.value(for: "device/os_name") as? String == "iOS")
    }

    @Test func testDeviceOSVersion() throws {
        #expect(try self.conversation.value(for: "device/os_version") as? Version == "13.0")
    }

    @Test func testDeviceOSBuild() throws {
        #expect(try self.conversation.value(for: "device/os_build") as? Version == "1")
    }

    @Test func testDeviceHardware() throws {
        #expect(try self.conversation.value(for: "device/hardware") as? String == "iPhone0,0")
    }

    @Test func testDeviceUUID() throws {
        #expect(try self.conversation.value(for: "device/uuid") as? UUID == self.conversation.device.uuid)
    }

    @Test func testDeviceCarrier() throws {
        self.conversation.device.carrier = "foo"

        #expect(try self.conversation.value(for: "device/carrier") as? String == "foo")
    }

    @Test func testDeviceLocaleCountryCode() throws {
        #expect(try self.conversation.value(for: "device/locale_country_code") as? String == "US")
    }

    @Test func testDeviceLocaleLanguageCode() throws {
        #expect(try self.conversation.value(for: "device/locale_language_code") as? String == "en")
    }

    @Test func testDeviceLocaleRaw() throws {
        #expect(try self.conversation.value(for: "device/locale_raw") as? String == "en_US")
    }

    @Test func testDeviceCustomData() throws {
        #expect(try self.conversation.value(for: "device/custom_data/string") == nil)
        #expect(try self.conversation.value(for: "device/custom_data/number") == nil)
        #expect(try self.conversation.value(for: "device/custom_data/boolean") == nil)

        self.conversation.device.customData["string"] = "string"
        self.conversation.device.customData["number"] = 5
        self.conversation.device.customData["boolean"] = true

        #expect(try self.conversation.value(for: "device/custom_data/string") as? String == "string")
        #expect(try self.conversation.value(for: "device/custom_data/number") as? Int == 5)
        #expect(try self.conversation.value(for: "device/custom_data/boolean") as? Bool == true)
    }

    @Test func testRandomPercent() throws {
        #expect(try self.conversation.value(for: "random/percent") as? Double == 50)
        #expect(try self.conversation.value(for: "random/xyz/percent") as? Double == 50)
    }
}
