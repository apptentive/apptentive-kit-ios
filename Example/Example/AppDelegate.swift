//
//  AppDelegate.swift
//  Example
//
//  Created by Frank Schmitt on 6/23/21.
//

import UIKit
import ApptentiveKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ApptentiveLogger.logLevel = .debug

        Apptentive.shared.register(credentials: Apptentive.AppCredentials(key: "<#Your Apptentive App Key#>", signature: "<#Your Apptentive App Signature#>"))

        return true
    }
}

