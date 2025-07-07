//
//  TargeterTests.swift
//
//
//  Created by Frank Schmitt on 10/4/19.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct TargeterTests {
    let targetingState = MockTargetingState()

    @Test func testManifest1() throws {
        guard let manifest = try manifest(for: #function) else {
            throw TestError(reason: "Unable to read manifest")
        }

        let targeter = Targeter(engagementManifest: manifest)

        #expect(try targeter.interactionData(for: "event_4", state: targetingState)?.id == "570694f855d9f42ce5000005")

        #expect(try targeter.interactionData(for: "nonexistent_event", state: targetingState) == nil)

        #expect(try targeter.interactionData(for: "launch", state: targetingState) == nil)
    }

    @Test func testNoManifest() throws {
        let targeter = Targeter(engagementManifest: EngagementManifest.placeholder)

        #expect(try targeter.interactionData(for: "event_4", state: targetingState)?.id == nil)
    }

    @Test func testBadInteractionRecoveryManifest() throws {
        guard let _ = try manifest(for: #function) else {
            throw TestError(reason: "Unable to read manifest")
        }
    }

    private func manifest(for testMethodName: String) throws -> EngagementManifest? {
        let testName = String(testMethodName.dropLast(2))  // strip parentheses from method name.
        guard let url = Bundle(for: BundleFinder.self).url(forResource: testName, withExtension: "json", subdirectory: "Test Manifests") else {
            throw TestError(reason: "Manifest not found for \(testName).json")
        }

        let data = try Data(contentsOf: url)

        return try JSONDecoder.apptentive.decode(EngagementManifest.self, from: data)
    }
}
