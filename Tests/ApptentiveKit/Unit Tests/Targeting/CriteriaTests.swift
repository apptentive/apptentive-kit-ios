////
////  CriteriaTests.swift
////
////
////  Created by Frank Schmitt on 9/26/19.
////

import XCTest

@testable import ApptentiveKit

final class CriteriaTests: XCTestCase {
    static let testResourceDirectory = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Test Criteria")
    let state = MockTargetingState()

    func testCornerCasesThatShouldBeFalse() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testCornerCasesThatShouldBeTrue() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testCriteriaDecoding() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testDefaultValues() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorAfter() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorBefore() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorContains() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorEndsWith() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorExists() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorGreaterThan() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorGreaterThanOrEqual() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorLessThan() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorLessThanOrEqual() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorNot() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorStartsWith() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorStringEquals() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testOperatorStringNotEquals() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testV7Criteria() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testWhitespaceTrimming() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    func testInteractionResponses() throws {
        XCTAssertTrue(try criteria(for: #function)?.isSatisfied(for: state) ?? false)
    }

    private func criteria(for testMethodName: String) -> Criteria? {
        let testName = String(testMethodName.dropLast(2))  // strip parentheses from method name.
        let url = Self.testResourceDirectory.appendingPathComponent(testName).appendingPathExtension("json")

        if let data = try? Data(contentsOf: url) {
            if let criteria = try? JSONDecoder.apptentive.decode(Criteria.self, from: data) {
                return criteria
            } else {
                XCTFail("Criteria parsing failed for \(testName)")
                return nil
            }
        } else {
            XCTFail("Test json dictionary not found for \(testName)")
            return nil
        }
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
