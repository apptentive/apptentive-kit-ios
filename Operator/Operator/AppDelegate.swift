//
//  AppDelegate.swift
//  Operator
//
//  Created by Frank Schmitt on 4/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var apptentive: Apptentive?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        ApptentiveLogger.logLevel = .debug

        self.registerDefaults()

        self.connect { result in
            switch result {
            case .success:
                print("Apptentive registration successful")

            case .failure(let error):
                print("Apptentive registration failed: \(error)")
            }
        }

        self.registerForPush()

        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if !self.apptentive!.didReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler) {
            print("Push was not handled by Apptentive. Calling completion handler")
            completionHandler(.noData)
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.apptentive?.setRemoteNotificationDeviceToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error).")
    }

    fileprivate func registerDefaults() {
        guard let defaultDefaultsURL = Bundle.main.url(forResource: "Defaults", withExtension: "plist"), let defaultDefaults = NSDictionary(contentsOf: defaultDefaultsURL) as? [String: AnyObject] else {
            preconditionFailure("Unable to read `Defaults.plist`. Please ensure you have renamed the `Defaults-Template.plist` file. See README.md for more information.")
        }

        UserDefaults.standard.register(defaults: defaultDefaults)
    }

    fileprivate func registerForPush() {
        UIApplication.shared.registerForRemoteNotifications()

        UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .alert]) { success, error in
            if !success, let error = error {
                print("Error requesting notification permissions: \(error).")
            } else {
                print("Success requesting notification permissions.")
            }
        }

        UNUserNotificationCenter.current().delegate = self.apptentive
    }

    fileprivate func connect(_ completion: @escaping ((Result<Void, Error>)) -> Void) {
        guard let key = UserDefaults.standard.string(forKey: "Key"), let signature = UserDefaults.standard.string(forKey: "Signature"), let urlString = UserDefaults.standard.string(forKey: "ServerURL"), let url = URL(string: urlString) else {
            completion(.failure(AppError.credentialsError))
            return
        }
        self.apptentive = Apptentive(apiBaseURL: url)

        self.apptentive?.register(with: .init(key: key, signature: signature), completion: completion)
    }
}

extension UIViewController {
    var apptentive: Apptentive {
        (UIApplication.shared.delegate as! AppDelegate).apptentive!
    }
}

extension UIWindow {
    // Detect shake gesture
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        let apptentive = (UIApplication.shared.delegate as! AppDelegate).apptentive!

        switch (UserDefaults.standard.string(forKey: "ShakeGestureAction")) {
        case "dismissAllInteractions":
            apptentive.dismissAllInteractions(animated: true)
        default:
            NSLog("No shake gesture action enabled.");
        }
    }
}

public enum AppError: Error {
    case credentialsError
}
