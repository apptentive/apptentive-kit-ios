//
//  Apptentive.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

public class Apptentive {
    let authenticator: Authenticating

    public convenience init() {
        // swift-format-ignore
        self.init(url: URL(string: "https://api.apptentive.com/conversations")!)
    }

    public convenience init(url: URL) {
        let authenticator = ApptentiveAuthenticator(url: url, requestor: URLSession.shared)
        self.init(authenticator: authenticator)
    }

    init(authenticator: Authenticating) {
        self.authenticator = authenticator
    }

    public func register(credentials: Credentials, completion: @escaping (Bool) -> Void) {
        self.authenticator.authenticate(credentials: credentials, completion: completion)
    }

    public struct Credentials {
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
