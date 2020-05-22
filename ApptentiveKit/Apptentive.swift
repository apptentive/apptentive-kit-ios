//
//  Apptentive.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

public class Apptentive {
    let baseURL: URL
    var client: ApptentiveClient? = nil

    public convenience init() {
        // swift-format-ignore
        self.init(baseURL: URL(string: "https://api.apptentive.com/")!)
    }

    public init(baseURL: URL) {
        self.baseURL = baseURL
    }

    public func register(credentials: AppCredentials, completion: @escaping (Bool) -> Void) {
        self.client = V9Client(url: baseURL, appCredentials: credentials, requestor: URLSession.shared, platform: Platform.current)
        self.client?.createConversation(completion: completion)
    }

    public struct AppCredentials {
        let key: String
        let signature: String

        public init(key: String, signature: String) {
            self.key = key
            self.signature = signature
        }
    }

    public func presentLoveDialog(from viewController: UIViewController, with configuration: LoveDialogConfiguration) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        let loveDialog = LoveDialogBuilder.build(with: configuration, appName: appName)

        viewController.present(loveDialog, animated: true)
    }
}
