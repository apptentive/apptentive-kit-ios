//
//  AppDelegate.swift
//  Operator
//
//  Created by Frank Schmitt on 4/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit
import Apptentive

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
	var apptentive: Apptentive!


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		self.registerDefaults()

		self.connect { result in
			print("Apptentive registration \(result ? "succeded" : "failed")");
		}

		return true
	}

	fileprivate func registerDefaults() {
		if let defaultDefaultsURL = Bundle.main.url(forResource: "Defaults", withExtension: "plist"), let defaultDefaults = NSDictionary(contentsOf:defaultDefaultsURL) as? [String : AnyObject] {
			UserDefaults.standard.register(defaults: defaultDefaults)
		}
	}

	fileprivate func connect(_ completion: @escaping (Bool) -> Void) {
		guard let key = UserDefaults.standard.string(forKey: "Key"), let signature = UserDefaults.standard.string(forKey: "Signature"), let urlString = UserDefaults.standard.string(forKey: "ServerURL"), let url = URL(string: urlString) else {
			completion(false)
			return;
		}

		self.apptentive = Apptentive(url: url)

		apptentive.register(credentials: Apptentive.Credentials(key: key, signature: signature), completion: completion)
	}
}

