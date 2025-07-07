//
//  Apptentive+Push.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/2/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit
@preconcurrency import UserNotifications

extension Apptentive: @preconcurrency UNUserNotificationCenterDelegate {
    /// Sets the remote notification device token to the specified value.
    /// - Parameter tokenData: The remote notification device token passed into `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.
    @objc public func setRemoteNotificationDeviceToken(_ tokenData: Data) {
        Task {
            await self.backend.setRemoteNotificationDeviceToken(tokenData)
        }
    }

    /// Should be called in response to the application delegate receiving a remote notification.
    ///
    /// - Note: If the return value is `false`, the caller is responsible for calling the fetch completion handler.
    /// - Parameters:
    ///   - userInfo: The `userInfo` parameter passed to `application(_:didReceiveRemoteNotification:)`.
    ///   - completionHandler: The `fetchCompletionHandler` parameter passed to `application(_:didReceiveRemoteNotification:)`.
    /// - Returns: `true` if the notification was handled by the Apptentive SDK, `false` if not.
    @objc public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @Sendable @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        guard let _ = userInfo["apptentive"] as? [String: Any] else {
            Logger.default.info("Non-apptentive push notification received.")
            return false
        }

        Logger.default.info("Apptentive push notification received with userInfo: \(userInfo).")
        if let userInfo = userInfo as? [String: any Sendable], let aps = userInfo["aps"] as? [String: any Sendable], let contentAvailable = aps["content-available"] as? Bool, contentAvailable {
            let isInForeground = self.environment.isInForeground

            Task {
                await fetchMessages(with: userInfo, shouldPostLocalNotification: aps["alert"] == nil || isInForeground)

                // Always send .newData so Apple doesn't throttle us.
                completionHandler(.newData)
            }
        } else {
            // Always send .newData so Apple doesn't throttle us.
            completionHandler(.newData)
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

        Logger.default.info("Apptentive user notification received.")
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
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @Sendable @escaping (UNNotificationPresentationOptions) -> Void) {
        let _ = self.willPresent(notification, withCompletionHandler: completionHandler)
    }

    /// Passes the arguments received by the delegate method to the appropriate Apptentive method.
    /// - Parameters:
    ///   - center: The user notification center.
    ///   - response: The user notification response.
    ///   - completionHandler: The completion handler to call.
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @Sendable @escaping () -> Void) {
        let _ = self.didReceveUserNotificationResponse(response, withCompletionHandler: completionHandler)
    }

    // MARK: - Private

    nonisolated private func presentMessageCenterIfNeeded(for userInfo: [AnyHashable: Any]) {
        guard let apptentive = userInfo["apptentive"] as? [String: Any] else {
            return
        }

        guard apptentive["action"] as? String == "pmc" else {
            return
        }

        Task {
            if await !self.interactionPresenter.messageCenterCurrentlyPresented {
                await self.presentMessageCenter(from: nil, completion: nil)
            }
        }
    }

    private func fetchMessages(with userInfo: [String: any Sendable], shouldPostLocalNotification: Bool) async {
        let fetchResult = await withCheckedContinuation { continuation in
            Task {
                await self.backend.setMessageFetchCompletionHandler { fetchResult in
                    // Post a user notification if no alert was displayed,
                    // either because this was a background push,
                    // or because the app is in the foreground.
                    continuation.resume(returning: fetchResult)
                }
            }
        }

        if fetchResult == .newData && shouldPostLocalNotification {
            self.postUserNotification(with: userInfo)
        }
    }

    private func postUserNotification(with userInfo: [AnyHashable: Any]) {
        guard self.environment.userNotificationCenterDelegateConfigured else {
            Logger.default.error(
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

        let userInfo = ["apptentive": userInfo["apptentive"] ?? [String: Any]()]
        let sound = soundName.flatMap { UNNotificationSound(named: UNNotificationSoundName(rawValue: $0)) } ?? .default

        self.environment.postLocalNotification(title: self.environment.appDisplayName, body: body, userInfo: userInfo, sound: sound)
    }
}
