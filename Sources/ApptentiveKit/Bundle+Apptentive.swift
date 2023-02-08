//
//  Bundle+Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

// Swift Package Manager synthesizes a `module` static property on `Bundle`.
// The code below exists to support the same behavior with other integration methods.
// This file is excluded from SPM integrations in our Package.swift file.
extension Bundle {
    #if SWIFT_PACKAGE
        static let apptentive = Bundle.module
    #else
        #if COCOAPODS
            // The SDK was integrated using CocoaPods. Look for a resource bundle nested in:
            // - The main bundle (if the Podfile does not call use_frameworks!)
            // - The framework bundle (if the Podfile calls use_frameworks!)
            // If neither is found, fall back to non-nested resources in the Apptentive framework
            // (this will likely fail, and we'll catch it in UIKit+Apptentive with an apptentiveCriticalError).
            static let apptentive: Bundle =
                Bundle.main.url(forResource: "ApptentiveKit", withExtension: "bundle").flatMap { Bundle(url: $0) }  // resource bundle nested in main bundle.
                ?? Bundle(for: Apptentive.self).url(forResource: "ApptentiveKit", withExtension: "bundle").flatMap { Bundle(url: $0) }  // resource bundle nested in Apptentive framework.
                ?? Bundle(for: Apptentive.self)  // no resource bundle.
        #else
            // The SDK was integrated by including the XCFramework (using Carthage or manual download).
            // Look for resources in the Apptentive framework.
            static let apptentive: Bundle = Bundle(for: Apptentive.self)
        #endif
    #endif
}
