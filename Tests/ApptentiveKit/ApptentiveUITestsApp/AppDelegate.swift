//
//  AppDelegate.swift
//  ApptentiveUITestsApp
//
//  Created by Frank Schmitt on 3/3/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Copy conversation data files so that the UI has stuff to display.
        do {
            let containerURL = try self.applicationSupportURL().appendingPathComponent("com.apptentive.feedback")

            try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])

            for dataURL in Bundle.main.urls(forResourcesWithExtension: "plist", subdirectory: "SDK Data") ?? [] {
                let destinationURL = containerURL.appendingPathComponent(dataURL.lastPathComponent)
                try? FileManager.default.removeItem(at: destinationURL)
                try FileManager.default.copyItem(at: dataURL, to: destinationURL)
            }
        } catch let error {
            print("Error copying conversation files: \(error)")
        }

        apptentiveAssertionHandler = { (message, file, line) in
            print("Hit assertion (\(message()) at line \(line) in \(file).")
        }

        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            keyWindow.layer.speed = UserDefaults.standard.float(forKey: "layerSpeed")
        }

        Apptentive.shared.theme = .none
        UIColor.apptentiveTermsOfServiceLabel = .white

        Apptentive.shared.register(with: .init(key: "IOS-IOS-AUTOMATED-TEST", signature: "bogus"), completion: nil)

        return true
    }

    func applicationSupportURL() throws -> URL {
        return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    func cachesURL() throws -> URL {
        return try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
}
