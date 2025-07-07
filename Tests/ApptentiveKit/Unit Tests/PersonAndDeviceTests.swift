//
//  PersonAndDeviceTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/26/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

// TODO: consider moving this to integration tests, or refactor to be more unit-y.

/// Person and device custom data (along with person name/email) have a few competing requirements:
/// 1. Host app should be able to write them on the main thread, using subscripts.
/// 2. Host app should be able to read them on the main thread without a callback (also with subscripts).
/// 3. Actual data is persisted on the backend queue (so that things like targeting and conversation management don't block the UI thread).
///
/// The solution used here is to have private "shadow" person and device objects
/// that buffer the current state of the person and device objects and update the backend.
///
/// Alongside the private person and device objects, public custom data objects
/// for each are exposed by the SDK (along with person name and email).
///
/// A write to any of these individual properties updates the shadow person/device (via `didSet`)
/// and also triggers an update to the backend's person/device (via explicit method call—
/// we can't use a `didSet` here because we'll sometimes need to update these
/// with information from the backend and don't want to create an infinite loop where
/// the backend updates the frontend and the frontend updates the backend and so on).
///
/// Fortunately the updating of the frontend's objects from the backend is quite limited.
/// It's mostly the SDK updating things on the server. The one instance where this is reversed
/// is when the backend loads a persisted conversation, which at that point in the app
/// lifecycle can be assumed to contain newer data than the frontend's objects.

@MainActor
struct PersonAndDeviceTests {
    var environment: MockEnvironment!
    var apptentive: Apptentive!
    var dispatchQueue: DispatchQueue!

    init() throws {
        try MockEnvironment.cleanContainerURL()

        self.dispatchQueue = DispatchQueue(label: "Test Queue")

        self.environment = MockEnvironment()
        self.environment?.isProtectedDataAvailable = false
        let containerDirectory = "com.apptentive.feedback.\(UUID().uuidString)"

        self.apptentive = Apptentive(baseURL: URL(string: "https://localhost"), containerDirectory: containerDirectory, backendQueue: self.dispatchQueue, environment: self.environment)

        Apptentive.alreadyInitialized = false

        // Clean up data directory before running tests
        let containerURL = MockEnvironment.applicationSupportURL.appendingPathComponent(containerDirectory)
        if FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.removeItem(at: containerURL)
        }
    }

    @Test func testPersonName() async {
        #expect(self.apptentive.personName == nil)

        self.apptentive.personName = "Testy McTestface"

        #expect(self.apptentive.personName == "Testy McTestface")

        let backendPersonName = await self.apptentive.backend.conversation?.person.name

        withKnownIssue {
            #expect("Testy McTestface" == backendPersonName)
        }
    }

    @Test func testPersonEmail() async {
        #expect(self.apptentive.personEmailAddress == nil)

        self.apptentive.personEmailAddress = "test@example.com"

        #expect(self.apptentive.personEmailAddress == "test@example.com")

        let backendPersonEmail = await self.apptentive.backend.conversation?.person.emailAddress

        withKnownIssue {
            #expect("test@example.com" == backendPersonEmail)
        }
    }

    @Test func testPersonCustomData() async {
        self.apptentive.personCustomData["string"] = "foo"
        self.apptentive.personCustomData["number"] = 42
        self.apptentive.personCustomData["boolean"] = true

        #expect(self.apptentive.personCustomData["string"] as? String == "foo")
        #expect(self.apptentive.personCustomData["number"] as? Int == 42)
        #expect(self.apptentive.personCustomData["boolean"] as? Bool == true)

        let backendCustomDataString = await self.apptentive.backend.conversation?.person.customData["string"] as? String
        let backendCustomDataNumber = await self.apptentive.backend.conversation?.person.customData["number"] as? Int
        let backendCustomDataBool = await self.apptentive.backend.conversation?.person.customData["boolean"] as? Bool

        withKnownIssue {
            #expect(backendCustomDataString == "foo")
            #expect(backendCustomDataNumber == 42)
            #expect(backendCustomDataBool == true)
        }
    }

    @Test func testDeviceCustomData() async {
        self.apptentive.deviceCustomData["string"] = "foo"
        self.apptentive.deviceCustomData["number"] = 42
        self.apptentive.deviceCustomData["boolean"] = true

        #expect(self.apptentive.deviceCustomData["string"] as? String == "foo")
        #expect(self.apptentive.deviceCustomData["number"] as? Int == 42)
        #expect(self.apptentive.deviceCustomData["boolean"] as? Bool == true)

        let backendCustomDataString = await self.apptentive.backend.conversation?.device.customData["string"] as? String
        let backendCustomDataNumber = await self.apptentive.backend.conversation?.device.customData["number"] as? Int
        let backendCustomDataBool = await self.apptentive.backend.conversation?.device.customData["boolean"] as? Bool

        withKnownIssue {
            #expect(backendCustomDataString == "foo")
            #expect(backendCustomDataNumber == 42)
            #expect(backendCustomDataBool == true)
        }
    }

    //    @Test func testUpdateFromBackend() {
    //        let containerDirectory = self.apptentive.containerDirectory
    //
    //        // Turn on disk access in the backend.
    //        self.environment.isProtectedDataAvailable = true
    //
    //        self.apptentive.personName = "Testy McTestface"
    //        self.apptentive.personEmailAddress = "test@example.com"
    //        self.apptentive.mParticleID = "abc123"
    //
    //        self.apptentive.personCustomData["string"] = "bar"
    //        self.apptentive.personCustomData["number"] = 43
    //        self.apptentive.personCustomData["boolean"] = false
    //
    //        self.apptentive.deviceCustomData["string"] = "bar"
    //        self.apptentive.deviceCustomData["number"] = 43
    //        self.apptentive.deviceCustomData["boolean"] = false
    //
    //        self.apptentive.protectedDataDidBecomeAvailable(self.apptentive.environment)
    //
    //        // Make sure the save operations on the backend queue have a chance to complete
    //        // By scheduling subsequent operations on the same (serial) queue.
    //
    //        self.dispatchQueue.async {
    //            self.apptentive.backend.saveToPersistentStorageIfNeeded()
    //
    //            DispatchQueue.main.async {
    //                Apptentive.alreadyInitialized = false
    //                self.environment.isProtectedDataAvailable = false
    //
    //                // Here we replace the Apptentive property with a new instance with no person/device properties set.
    //                self.apptentive = Apptentive(baseURL: URL(string: "https://localhost"), containerDirectory: containerDirectory, backendQueue: self.dispatchQueue, environment: self.environment)
    //
    //                // Before loading, everything should be nil
    //                #expect(self.apptentive.personName == nil)
    //                #expect(self.apptentive.personEmailAddress == nil)
    //
    //                #expect(self.apptentive.personCustomData["string"] == nil)
    //                #expect(self.apptentive.personCustomData["number"] == nil)
    //                #expect(self.apptentive.personCustomData["boolean"] == nil)
    //
    //                #expect(self.apptentive.deviceCustomData["string"] == nil)
    //                #expect(self.apptentive.deviceCustomData["number"] == nil)
    //                #expect(self.apptentive.deviceCustomData["boolean"] == nil)
    //
    //                // Now we load the data (from "disk") that the original apptentive instance saved.
    //                self.apptentive.protectedDataDidBecomeAvailable(self.apptentive.environment)
    //
    //                // Make sure the backend's `load` method completes by scheduling assertions on the same (serial) queue.
    //                self.dispatchQueue.async {
    //                    DispatchQueue.main.async {
    //                        #expect(self.apptentive.personName == "Testy McTestface")
    //                        #expect(self.apptentive.personEmailAddress == "test@example.com")
    //                        #expect(self.apptentive.mParticleID == "abc123")
    //
    //                        #expect(self.apptentive.personCustomData["string"] as? String == "bar")
    //                        #expect(self.apptentive.personCustomData["number"] as? Int == 43)
    //                        #expect(self.apptentive.personCustomData["boolean"] as? Bool == false)
    //
    //                        #expect(self.apptentive.deviceCustomData["string"] as? String == "bar")
    //                        #expect(self.apptentive.deviceCustomData["number"] as? Int == 43)
    //                        #expect(self.apptentive.deviceCustomData["boolean"] as? Bool == false)
    //
    //                        expect.fulfill()
    //                    }
    //                }
    //            }
    //        }
    //
    //        wait(for: [expect], timeout: 5)
    //    }
}
