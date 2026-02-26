////
////  CriteriaTests.swift
////
////
////  Created by Frank Schmitt on 9/26/19.
////

import Foundation
import Testing

@testable import ApptentiveKit

// Criteria logger is not reentrancy-safe (relies on Backend actor isolation) so serialize these tests.
@Suite(.serialized) struct CriteriaTests {
    let state = MockTargetingState()

    @Test(arguments: [
        "testCodePointInvokesTotal",
        "testCodePointInvokesVersion",
        "testCodePointLastInvokedAt",
        "testCornerCasesThatShouldBeFalse",
        "testCornerCasesThatShouldBeTrue",
        "testCriteriaDecoding",
        "testDefaultValues",
        "testInteractionInvokesTotal",
        "testInteractionResponses",
        "testOperatorAfter",
        "testOperatorBefore",
        "testOperatorContains",
        "testOperatorEndsWith",
        "testOperatorExists",
        "testOperatorGreaterThan",
        "testOperatorGreaterThanOrEqual",
        "testOperatorLessThan",
        "testOperatorLessThanOrEqual",
        "testOperatorNot",
        "testOperatorStartsWith",
        "testOperatorStringEquals",
        "testOperatorStringNotEquals",
        "testV7Criteria",
        "testWhitespaceTrimming",
    ]) func testCriteria(in file: String) throws {
        #expect(try criteria(for: file)?.isSatisfied(for: state) == true)
    }

    private func criteria(for testName: String) throws -> Criteria? {
        let url = Bundle(for: BundleFinder.self).url(forResource: testName, withExtension: "json", subdirectory: "Test Criteria")!

        let data = try Data(contentsOf: url)
        return try JSONDecoder.apptentive.decode(Criteria.self, from: data)
    }
}

struct MockTargetingState: TargetingState {
    func value(for field: Field) -> Any? {
        switch cleanField(field.fullPath) {
        case "device/custom_data/number_5":
            return 5
        case "device/custom_data/string_qwerty":
            return "qwerty"
        case "device/custom_data/string with spaces":
            return "string with spaces"
        case "device/custom_data/key_with_null_value":
            return nil
        case "application/cf_bundle_short_version_string", "application/cf_bundle_version":
            return Version(string: "6.0.0")
        case "current_time", "time_at_install/total", "time_at_install/cf_bundle_short_version_string", "time_at_install/cf_bundle_version":
            return Date()
        case "is_update/cf_bundle_short_version_string", "is_update/cf_bundle_version":
            return false
        case "code_point/test.code.point/last_invoked_at/total":
            return Date()
        case "code_point/test.code.point/invokes/total",
            "code_point/test.code.point/invokes/cf_bundle_short_version_string":
            return 2
        case "code_point/invalid_code_point/invokes/total", "code_point/invalid_code_point/invokes/cf_bundle_short_version_string", "interactions/invalid_interaction/invokes/total",
            "interactions/invalid_interaction/invokes/cf_bundle_short_version_string":
            return 0
        case "device/custom_data/version_1.2.3":
            return Version(string: "1.2.3")
        case "device/custom_data/datetime_1000":
            return Date(timeIntervalSince1970: 1000)
        case "device/custom_data/boolean_true":
            return true
        case "interactions/did_not_respond/answers/value":
            return Set<Answer.Value>()
        case "interactions/did_not_respond/answers/id":
            return Set<Answer.Value>()
        case "interactions/range_question/answers/value":
            return Set([-2, 0, 2].map { Answer.Value.int($0) })
        case "interactions/freeform_question/answers/value":
            return Set(["yah", "sure", "youbetcha"].map { Answer.Value.string($0) })
        case "interactions/choice_question/answers/id":
            return Set(["abc123", "def456"])
        case "interactions/other_question/answers/id":
            return Set(["ghi123", "jkl456"])
        case "interactions/other_question/answers/value":
            return Set(["Gee", "Just Kidding"].map { Answer.Value.string($0) })

        default:
            return nil
        }
    }

    func cleanField(_ field: String) -> String {
        let parts = field.split(separator: "/").map { String($0).trimmedAndLowercased() }

        return parts.joined(separator: "/")
    }
}

extension String {
    fileprivate func trimmedAndLowercased() -> String {
        return self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
