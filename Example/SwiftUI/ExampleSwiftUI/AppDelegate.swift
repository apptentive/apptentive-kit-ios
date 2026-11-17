//
//  AppDelegate.swift
//  ExampleSwiftUI
//
//  Created by Frank Schmitt on 5/11/23.
//

import UIKit
import ApptentiveKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        Apptentive.shared.register(with: .init(key: "<#Your Apptentive App Key#>", signature: "<#Your Apptentive App Signature#>"))

        return true
    }
}
