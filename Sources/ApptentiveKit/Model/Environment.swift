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
protocol GlobalEnvironment {
    var fileManager: FileManager { get }
    var isInForeground: Bool { get }
    var isProtectedDataAvailable: Bool { get }
    var delegate: EnvironmentDelegate? { get set }
    var isTesting: Bool { get }
    var appDisplayName: String { get }

    func requestReview(completion: @escaping (Bool) -> Void)
    func open(_ url: URL, completion: @escaping (Bool) -> Void)
}

/// Allows the Environment to communicate changes.
protocol EnvironmentDelegate: AnyObject {

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
class Environment: GlobalEnvironment {

    /// The file manager that should be used when interacting with the filesystem.
    let fileManager: FileManager

    /// Whether the app has access to the encrypted filesystem.
    var isProtectedDataAvailable: Bool

    /// The display name of the app.
    let appDisplayName: String

    /// Whether the application is in the foreground.
    var isInForeground: Bool

    /// Checks the environment to see if testing is taking place.
    var isTesting: Bool

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

        self.isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

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

    /// Requests a review using `SKStoreReviewController`.
    ///
    /// If no review window appears within 1 second of the request, assume the request was denied.
    /// - Parameter completion: Called with a value indicating whether the review request was shown.
    func requestReview(completion: @escaping (Bool) -> Void) {
        #if canImport(StoreKit)
            var didShow = false

            // Prepare to observe when a window appears.
            NotificationCenter.default.addObserver(forName: UIWindow.didBecomeVisibleNotification, object: nil, queue: nil) { (notification) in
                if let object = notification.object, String(describing: type(of: object)).hasPrefix("SKStoreReview") {
                    // If the window looks store-review-related, note that the system showed the review request.
                    didShow = true
                }
            }

            // Request a review.
            SKStoreReviewController.requestReview()

            // Wait up to 1 second for the review window to appear before giving up.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                NotificationCenter.default.removeObserver(self, name: UIWindow.didBecomeVisibleNotification, object: nil)

                completion(didShow)
            }
        #else
            completion(false)
        #endif
    }

    /// Asks the system to open the specified URL.
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - completion: Called with a value indicating whether the URL was successfully opened.
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        #if canImport(UIKit)
            UIApplication.shared.open(url, options: [:], completionHandler: completion)
        #else
            completion(false)
        #endif
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
