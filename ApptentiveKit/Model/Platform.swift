//
//  Platform.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/14/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

protocol PlatformProtocol {
    static var current: PlatformProtocol { get }

    var sdkVersion: Version { get }
}

#if canImport(UIKit)

    import UIKit

    class Platform: PlatformProtocol {
        static let current: PlatformProtocol = Platform()

        lazy var sdkVersion: Version = {
            guard let versionString = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String else {
                assertionFailure("Unable to read SDK version from ApptentiveKit's Info.plist file")
                return "Unavailable"
            }

            return Version(string: versionString)
        }()
    }

#endif
