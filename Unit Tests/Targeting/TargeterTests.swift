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
    static let testResourceDirectory = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Test Manifests")

    func testManifest1() throws {
        guard let manifest = manifest(for: #function) else {
            return XCTFail()
        }

        let targeter = Targeter(engagementManifest: manifest)

        XCTAssertEqual(try targeter.interactionData(for: "event_4")?.id, "570694f855d9f42ce5000005")

        XCTAssertNil(try targeter.interactionData(for: "nonexistent_event"))
    }

    func testNoManifest() throws {
        let targeter = Targeter()

        XCTAssertNil(try targeter.interactionData(for: "event_4")?.id)
    }

    static var allTests = [
        ("testManifest1", testManifest1),
        ("testNoManifest", testNoManifest)
    ]

    private func manifest(for testMethodName: String) -> EngagementManifest? {
        let testName = String(testMethodName.dropLast(2)) // strip parentheses from method name
        let url = Self.testResourceDirectory.appendingPathComponent(testName).appendingPathExtension("json")

        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            //decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let manifest = try? decoder.decode(EngagementManifest.self, from: data) {
                return manifest
            } else {
                XCTFail("Manifest parsing failed for \(testName)")
                return nil
            }
        } else {
            XCTFail("Test json dictionary not found for \(testName)")
            return nil
        }
    }
}
