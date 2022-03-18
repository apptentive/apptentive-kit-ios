//
//  Apptentive+Push.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/2/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

extension Apptentive: UNUserNotificationCenterDelegate {
    /// Sets the remote notification device token to the specified value.
    /// - Parameter tokenData: The remote notification device token passed into application(_:didRegisterForRemoteNotificationsWithDeviceToken:).
    public func setRemoteNotifcationDeviceToken(_ tokenData: Data) {
        self.backendQueue.async {
            let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            self.backend.conversation.device.integrationConfiguration["apptentive_push"] = ["token": tokenString]
        }
    }

    /// Should be called in response to the application delegate receiving a remote notification.
    ///
    /// - Note: If the return value is `false`, the caller is responsible for calling the fetch completion handler.
    /// - Parameters:
    ///   - userInfo: The `userInfo` parameter passed to `application(_:didReceiveRemoteNotification:)`.
    ///   - completionHandler: The `fetchCompletionHandler` parameter passed to `application(_:didReceiveRemoteNotification:)`.
    /// - Returns: `true` if the notification was handled by the Apptentive SDK, `false` if not.
    @objc public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard let _ = userInfo["apptentive"] else {
            ApptentiveLogger.default.info("Non-apptentive push notification received.")
            return false
        }

        ApptentiveLogger.default.info("Apptentive push notification received.")
        self.backendQueue.async {
            if let aps = userInfo["aps"] as? [String: Any], let contentAvailable = aps["content-available"] as? Bool, contentAvailable {
                self.fetchMessages { success in
                    DispatchQueue.main.async {
                        completionHandler(success ? .newData : .failed)
                    }
                }

                // Post a user notification if no alert was displayed,
                // either because this was a background push,
                // or because the app is in the foreground.
                if aps["alert"] == nil || self.environment.isInForeground {
                    DispatchQueue.main.async {
                        self.postUserNotification(with: userInfo)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(.noData)
                }
            }
        }

        return true
    }

    /// Called when a user responds to a user notification.
    ///
    /// Apps may set their ``Apptentive`` instance as the delegate of the current `UNUserNotificationCenter`.
    /// If another object assumes this role, it should call this method in `userNotificationCenter(_:didReceive:withCompletionHandler:)`.
    /// - Note: If this method returns `false`, the caller is responsible for calling the completion handler.
    /// - Parameters:
    ///   - response: The `response` parameter passed to `userNotificationCenter(_:didReceive:withCompletionHandler:)`.
    ///   - completionHandler: The `completionHandler` parameter passed to `userNotificationCenter(_:didReceive:withCompletionHandler:)`.
    /// - Returns: `true` if the notification was handled by the Apptentive SDK, `false` if not.
    @objc public func didReceveUserNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
        guard let _ = response.notification.request.content.userInfo["apptentive"] else {
            return false
        }

        ApptentiveLogger.default.info("Apptentive user notification received.")
        self.presentMessageCenterIfNeeded(for: response.notification.request.content.userInfo)
        completionHandler()
        return true
    }

    /// Called when a user notification will be displayed.
    ///
    /// Apps may set their ``Apptentive`` instance as the delegate of the current `UNUserNotificationCenter`.
    /// If another object assumes this role, it should call this method in `userNotificationCenter(_:willPresent:notification:completionHandler:)`.
    /// - Note: If this method returns `false`, the caller is responsible for calling the completion handler.
    /// - Parameters:
    ///   - notification: The `response` parameter passed to `userNotificationCenter(_:willPresent:notification:withCompletionHandler:)`.
    ///   - completionHandler: The `completionHandler` parameter passed to `userNotificationCenter(_:willPresent:notification:withCompletionHandler:)`.
    /// - Returns: `true` if the notification was handled by the Apptentive SDK, `false` if not.
    @objc public func willPresent(_ notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
        guard let _ = notification.request.content.userInfo["apptentive"] else {
            return false
        }

        if notification.request.trigger is UNPushNotificationTrigger {
            completionHandler([])
        } else {
            if #available(iOS 14.0, *) {
                completionHandler(.banner)
            } else {
                completionHandler(.alert)
            }
        }

        return true
    }

    // MARK: - User Notification Center Delegate

    /// Passes the arguments received by the delegate method to the appropriate Apptentive method.
    /// - Parameters:
    ///   - center: The user notification center.
    ///   - notification: The user notification.
    ///   - completionHandler: The completion handler to call.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let _ = self.willPresent(notification, withCompletionHandler: completionHandler)
    }

    /// Passes the arguments received by the delegate method to the appropriate Apptentive method.
    /// - Parameters:
    ///   - center: The user notification center.
    ///   - response: The user notification response.
    ///   - completionHandler: The completion handler to call.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let _ = self.didReceveUserNotificationResponse(response, withCompletionHandler: completionHandler)
    }

    // MARK: - Private

    private func presentMessageCenterIfNeeded(for userInfo: [AnyHashable: Any]) {
        guard let apptentive = userInfo["apptentive"] as? [String: Any] else {
            return
        }

        if apptentive["pmc"] as? Bool == true {
            self.presentMessageCenter(from: nil, completion: nil)
        }
    }

    private func fetchMessages(_ completionHandler: @escaping (Bool) -> Void) {
        self.backendQueue.async {
            self.backend.getMessagesIfNeeded { success in
                completionHandler(success)
            }
        }
    }

    private func postUserNotification(with userInfo: [AnyHashable: Any]) {
        guard let delegate = UNUserNotificationCenter.current().delegate, delegate.responds(to: #selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))) else {
            ApptentiveLogger.default.error(
                """
                Your app is not properly configured to accept Apptentive push notifications.
                Please see the push notification section of the integration guide for assistance:
                https://learn.apptentive.com/knowledge-base/ios-integration-reference/#push-notifications.
                """)
            return
        }

        var body: String = "A new message awaits you in Message Center"
        var soundName: String?

        if let apptentive = userInfo["apptentive"] as? [String: Any], let alert = apptentive["alert"] as? String {
            body = alert
            soundName = apptentive["sound"] as? String
        } else if let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? String {
            body = alert
            soundName = aps["sound"] as? String
        }

        let content = UNMutableNotificationContent()
        content.title = self.environment.appDisplayName
        content.body = body
        content.userInfo = ["apptentive": userInfo["apptentive"] ?? [:]]
        content.sound = soundName.flatMap { UNNotificationSound(named: UNNotificationSoundName(rawValue: $0)) } ?? .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "com.apptentive", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                ApptentiveLogger.default.error("Error adding user notification: \(error)")
            }
        }
    }
}
