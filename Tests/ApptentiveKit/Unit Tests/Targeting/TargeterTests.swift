//
//  TargeterTests.swift
//
//
//  Created by Frank Schmitt on 10/4/19.
//

import Foundation
import XCTest

@testable import ApptentiveKit

final class TargeterTests: XCTestCase {
    let targetingState = MockTargetingState()

    func testManifest1() throws {
        guard let manifest = try manifest(for: #function) else {
            return XCTFail()
        }

        let targeter = Targeter(engagementManifest: manifest)

        XCTAssertEqual(try targeter.interactionData(for: "event_4", state: targetingState)?.id, "570694f855d9f42ce5000005")

        XCTAssertNil(try targeter.interactionData(for: "nonexistent_event", state: targetingState))

        XCTAssertNil(try targeter.interactionData(for: "launch", state: targetingState))
    }

    func testNoManifest() throws {
        let targeter = Targeter(engagementManifest: EngagementManifest.placeholder)

        XCTAssertNil(try targeter.interactionData(for: "event_4", state: targetingState)?.id)
    }

    static var allTests = [
        ("testManifest1", testManifest1),
        ("testNoManifest", testNoManifest),
    ]

    private func manifest(for testMethodName: String) throws -> EngagementManifest? {
        let testName = String(testMethodName.dropLast(2))  // strip parentheses from method name.
        guard let url = Bundle(for: type(of: self)).url(forResource: testName, withExtension: "json", subdirectory: "Test Manifests") else {
            throw TargeterTestError.manifestNotFound
        }

        let data = try Data(contentsOf: url)

        return try JSONDecoder().decode(EngagementManifest.self, from: data)
    }
}

enum TargeterTestError: Error {
    case manifestNotFound
}
