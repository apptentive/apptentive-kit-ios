//
//  AppDelegate.swift
//  Operator
//
//  Created by Frank Schmitt on 4/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

struct Credentials {
    let appCredentials: Apptentive.AppCredentials
    let jwtSigningSecret: String?
    let region: Apptentive.Region
    let environment: Apptentive.Environment
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @Sendable @escaping (UIBackgroundFetchResult) -> Void) {
        guard let apptentive = SceneDelegate.current?.apptentive else {
            return completionHandler(.newData)
        }
        if !apptentive.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler) {
            print("Push was not handled by Apptentive. Calling completion handler")
            completionHandler(.newData)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for remote notifications: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined()).")
        SceneDelegate.current?.apptentive?.setRemoteNotificationDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error).")
    }
}

extension UIViewController {
    var apptentive: Apptentive {
        guard let apptentive = SceneDelegate.current?.apptentive else {
            preconditionFailure("Apptentive not initialized")
        }
        return apptentive
    }
}

extension UIWindow {
    // Detect shake gesture
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard let apptentive = SceneDelegate.current?.apptentive else { return }
        switch UserDefaults.standard.string(forKey: "ShakeGestureAction") {
        case "dismissAllInteractions":
            apptentive.dismissAllInteractions(animated: true)
        default:
            NSLog("No shake gesture action enabled.")
        }
    }
}

public enum AppError: Error {
    case credentialsError
}
