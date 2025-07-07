//
//  Environment.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/8/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(CoreTelephony)
    import CoreTelephony
#endif

#if canImport(StoreKit)
    import StoreKit
#endif

/// The portions of the Environment that provide access to platform features.
@MainActor protocol GlobalEnvironment {
    var fileManager: FileManaging { get }
    var isInForeground: Bool { get }
    var isProtectedDataAvailable: Bool { get }
    var delegate: EnvironmentDelegate? { get set }
    var appDisplayName: String { get }

    func requestReview() async throws -> Bool
    func open(_ url: URL) async -> Bool

    var userNotificationCenterDelegateConfigured: Bool { get }
    func postLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any], sound: UNNotificationSound)
}

/// Allows the Environment to communicate changes.
@MainActor protocol EnvironmentDelegate: AnyObject {

    /// Notifies the receiver that access to protected data (from the encrypted filesystem) is now available.
    /// - Parameter environment: The environment calling the method.
    func protectedDataDidBecomeAvailable(_ environment: GlobalEnvironment)

    /// Notifies the receiver that access to protected data (from the encrypted filesystem) will no longer be available.
    /// - Parameter environment: The environment calling the method.
    func protectedDataWillBecomeUnavailable(_ environment: GlobalEnvironment)

    /// Notifies the receiver that the application will enter the foreground.
    /// - Parameter environment: The environment calling the method.
    func applicationWillEnterForeground(_ environment: GlobalEnvironment)

    /// Notifies the receiver that the application did enter the background.
    /// - Parameter environment: The environment calling the method.
    func applicationDidEnterBackground(_ environment: GlobalEnvironment)

    /// Notifies the receiver that the application will terminate.
    /// - Parameter environment: The environment calling the method.
    func applicationWillTerminate(_ environment: GlobalEnvironment)

}

/// Provides access to platform, device, and operating system information.
///
/// Allows these values to be injected as a dependency to aid in testing.
@MainActor final class Environment: GlobalEnvironment {

    /// The file manager that should be used when interacting with the filesystem.
    let fileManager: FileManaging

    /// Whether the app has access to the encrypted filesystem.
    var isProtectedDataAvailable: Bool

    /// The display name of the app.
    let appDisplayName: String

    /// Whether the application is in the foreground.
    var isInForeground: Bool

    /// The delegate to notify when aspects of the environment change.
    weak var delegate: EnvironmentDelegate?

    /// Initializes a new environment based on values captured from the operating system.
    init() {
        self.fileManager = FileManager.default

        let infoDictionary = Bundle.main.infoDictionary
        let localizedInfoDictionary = Bundle.main.localizedInfoDictionary

        let possibleDisplayNames: [String?] = [
            localizedInfoDictionary?["CFBundleDisplayName"] as? String,
            localizedInfoDictionary?["CFBundleName"] as? String,
            infoDictionary?["CFBundleDisplayName"] as? String,
            infoDictionary?["CFBundleName"] as? String,
        ]

        self.appDisplayName = possibleDisplayNames.compactMap { $0 }.first ?? "App"

        #if canImport(UIKit)
            self.isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
            self.isInForeground = UIApplication.shared.applicationState != .background
        #else
            self.isProtectedDataAvailable = true
            self.isInForeground = true
        #endif

        #if canImport(UIKit)
            NotificationCenter.default.addObserver(self, selector: #selector(protectedDataDidBecomeAvailable(notification:)), name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(protectedDataWillBecomeUnavailable(notification:)), name: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        #endif
    }

    private var ratingDialogDidShow = false

    /// Requests a review using `SKStoreReviewController`.
    ///
    /// If no review window appears within 1 second of the request, assume the request was denied.
    /// - Returns: A value indicating whether the review request was shown.
    /// - Throws: An error if requesting the review fails.
    func requestReview() async throws -> Bool {
        self.ratingDialogDidShow = false

        #if canImport(StoreKit)
            // Prepare to observe when a window appears.
            NotificationCenter.default.addObserver(forName: UIWindow.didBecomeVisibleNotification, object: nil, queue: nil) { (notification) in
                if let object = notification.object, String(describing: type(of: object)).hasPrefix("SKStoreReview") {
                    // If the window looks store-review-related, note that the system showed the review request.
                    Task { @MainActor in
                        self.ratingDialogDidShow = true
                    }
                }
            }

            // Request a review.
            if let activeScene = UIApplication.shared.firstActiveScene {
                SKStoreReviewController.requestReview(in: activeScene)
            } else {
                throw ApptentiveError.internalInconsistency
            }

            // Wait 1 second to give window a chance to appear.
            try await Task.sleep(nanoseconds: 1 * NSEC_PER_SEC)
        #endif

        return self.ratingDialogDidShow
    }

    /// Asks the system to open the specified URL.
    /// - Parameter url: The URL to open.
    /// - Returns: A value indicating whether the URL was successfully opened.
    func open(_ url: URL) async -> Bool {
        #if canImport(UIKit)
            return await UIApplication.shared.open(url)
        #else
            return false
        #endif
    }

    var userNotificationCenterDelegateConfigured: Bool {
        if let delegate = UNUserNotificationCenter.current().delegate, delegate.responds(to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))) {
            return true
        } else {
            return false
        }
    }

    func postLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any], sound: UNNotificationSound) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo = userInfo
        content.sound = sound

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "com.apptentive", content: content, trigger: trigger)

        Task {
            try await UNUserNotificationCenter.current().add(request)
        }

    }

    #if canImport(UIKit)
        @objc func protectedDataDidBecomeAvailable(notification: Notification) {
            self.isProtectedDataAvailable = true
            delegate?.protectedDataDidBecomeAvailable(self)
        }

        @objc func protectedDataWillBecomeUnavailable(notification: Notification) {
            self.isProtectedDataAvailable = false
            delegate?.protectedDataWillBecomeUnavailable(self)
        }

        @objc func applicationWillEnterForeground(notification: Notification) {
            delegate?.applicationWillEnterForeground(self)
            self.isInForeground = true
        }

        @objc func applicationDidEnterBackground(notification: Notification) {
            delegate?.applicationDidEnterBackground(self)
            self.isInForeground = false
        }

        @objc func applicationWillTerminate(notification: Notification) {
            delegate?.applicationWillTerminate(self)
            self.isInForeground = false
        }
    #endif

    static func getDeviceIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)

        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        return machine
    }
}
