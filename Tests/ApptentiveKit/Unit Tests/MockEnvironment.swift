//
//  MockEnvironment.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 9/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

@testable import ApptentiveKit

struct MockEnvironment: GlobalEnvironment {
    static let applicationSupportURL = URL(fileURLWithPath: "/tmp/")
    static let cachesURL = URL(fileURLWithPath: "/tmp/caches/")
    static let containerName = "com.apptentive.feedback"

    static func cleanContainerURL() throws {
        let containerURL = self.applicationSupportURL.appendingPathComponent(self.containerName)

        if FileManager.default.fileExists(atPath: containerURL.path) {
            try? FileManager.default.removeItem(at: containerURL)
        }

        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
    }

    var isTesting = true

    var fileManager = FileManager.default
    var isInForeground = true
    var isProtectedDataAvailable = true
    var delegate: EnvironmentDelegate?
    var remoteNotificationDeviceToken: Data?

    var appDisplayName: String = "This Nifty App"

    var shouldOpenURLSucceed = true
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        completion(self.shouldOpenURLSucceed)
    }

    var shouldRequestReviewSucceed = true
    func requestReview(completion: @escaping (Bool) -> Void) {
        completion(shouldRequestReviewSucceed)
    }

    func startBackgroundTask() {}
    func endBackgroundTask() {}
}
