//
//  SceneDelegate.swift
//  Operator
//
//  Created by Frank Schmitt on 4/22/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate, ApptentiveDelegate {
    var window: UIWindow?
    var apptentive: Apptentive?

    static var current: SceneDelegate? {
        UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
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
    }

    func authenticationDidFail(with error: Error) {
        print("Authentication failed with error: \(error)")
    }

    private func registerDefaults() {
        guard let defaultDefaultsURL = Bundle.main.url(forResource: "Defaults", withExtension: "plist"),
              let defaultDefaults = NSDictionary(contentsOf: defaultDefaultsURL) as? [String: AnyObject]
        else {
            preconditionFailure("Unable to read `Defaults.plist`. Please ensure you have renamed the `Defaults-Template.plist` file. See README.md for more information.")
        }

        UserDefaults.standard.register(defaults: defaultDefaults)
    }

    private func registerForPush() {
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

    private func connect(_ completion: @Sendable @escaping (Result<Void, Error>) -> Void) {
        self.apptentive = Apptentive.shared
        self.apptentive?.delegate = self

        UserDefaults.standard.set(Credentials.active.jwtSigningSecret, forKey: "APPTENTIVE_JWT_SECRET")

        self.apptentive?.register(
            with: Credentials.active.appCredentials,
            region: Credentials.active.region,
            environment: Credentials.active.environment,
            completion: completion
        )
    }
}
