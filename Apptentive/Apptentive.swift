//
//  Apptentive.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import UIKit


public class Apptentive {
    let authenticator: Authenticating
    
    public convenience init() {
        
        let url = URL(string: "https://api.apptentive.com/conversations")!
        let authenticator = ApptentiveAuthenticator(url: url, requestor: URLSession.shared)
        self.init(authenticator: authenticator)
    }
    
    init(authenticator: Authenticating) {
        self.authenticator = authenticator
    }
    
    public func register(credentials: Credentials, completion: @escaping (Bool)->()) {
        self.authenticator.authenticate(credentials: credentials, completion: completion)
    }
    
    public struct Credentials {
        let key: String
        let signature: String
    }
    
    public func presentLoveDialog(from viewController: UIViewController, with configuration: LoveDialogConfiguration) {
        let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
        let loveDialog = LoveDialogBuilder.build(with: configuration, appName: appName)
        
        viewController.present(loveDialog, animated: true)
    }
}
