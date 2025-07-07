//
//  MockEnvironment.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 9/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

@testable import ApptentiveKit

class MockEnvironment: GlobalEnvironment {
    var userNotificationCenterDelegateConfigured: Bool = true

    var localNotificationTitle: String?
    var localNotificationBody: String?
    var localNotificationUserInfo: [String: [String: String]]?
    var localNotificationSound: UNNotificationSound?

    func postLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any], sound: UNNotificationSound) {
        self.localNotificationTitle = title
        self.localNotificationBody = body
        self.localNotificationUserInfo = userInfo as? [String: [String: String]]
        self.localNotificationSound = sound
    }

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

    var fileManager: FileManaging = MockFileManager()
    var isInForeground = true
    var isProtectedDataAvailable = true
    var delegate: EnvironmentDelegate?
    var remoteNotificationDeviceToken: Data?

    var appDisplayName: String = "This Nifty App"

    var shouldRequestReviewSucceed = true
    func requestReview() async throws -> Bool {
        return self.shouldOpenURLSucceed
    }

    var shouldOpenURLSucceed = true
    func open(_ url: URL) async -> Bool {
        return self.shouldOpenURLSucceed
    }
}
