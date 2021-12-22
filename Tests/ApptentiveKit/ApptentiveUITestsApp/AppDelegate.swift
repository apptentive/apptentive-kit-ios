//
//  AppDelegate.swift
//  ApptentiveUITestsApp
//
//  Created by Frank Schmitt on 3/3/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit
import ApptentiveKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.

        do {
            let containerURL = try self.applicationSupportURL().appendingPathComponent("com.apptentive.feedback")

            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])

            for dataURL in Bundle.main.urls(forResourcesWithExtension: "plist", subdirectory: "SDK Data") ?? [] {
                let destinationURL = containerURL.appendingPathComponent(dataURL.lastPathComponent)
                try? FileManager.default.removeItem(at: destinationURL)
                try FileManager.default.copyItem(at: dataURL, to: destinationURL)
            }
        } catch let error {
            print("Error copying message list: \(error)")
        }

        return true
    }

    func applicationSupportURL() throws -> URL {
        return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}
