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
            case .success(true):
                print("Apptenitve registration successful")
            case .success(false):
                print("Apptentive registration not successful.")
            case .failure(let error):
                print("Apptentive registration failed: \(error)")
            }

        }

        return true
    }

    fileprivate func registerDefaults() {
        guard let defaultDefaultsURL = Bundle.main.url(forResource: "Defaults", withExtension: "plist"), let defaultDefaults = NSDictionary(contentsOf: defaultDefaultsURL) as? [String: AnyObject] else {
            preconditionFailure("Unable to read `Defaults.plist`. Please ensure you have renamed the `Defaults-Template.plist` file. See README.md for more information.")
        }

        UserDefaults.standard.register(defaults: defaultDefaults)
    }

    fileprivate func connect(_ completion: @escaping ((Result<Bool, Error>)) -> Void) {
        guard let key = UserDefaults.standard.string(forKey: "Key"), let signature = UserDefaults.standard.string(forKey: "Signature"), let urlString = UserDefaults.standard.string(forKey: "ServerURL"), let url = URL(string: urlString) else {
            completion(.failure(AppError.credentialsError))
            return
        }
        self.apptentive = Apptentive(apiBaseURL: url)
        apptentive?.register(credentials: Apptentive.AppCredentials(key: key, signature: signature), completion: completion)
    }
}
extension UIViewController {
    var apptentive: Apptentive {
        (UIApplication.shared.delegate as! AppDelegate).apptentive!
    }
}

public enum AppError: Error {
    case credentialsError
}
