//
//  Bundle+Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

extension Bundle {
    #if COCOAPODS
        static let module: Bundle = Bundle.main.url(forResource: "ApptentiveKit", withExtension: "bundle").flatMap { Bundle(url: $0) } ?? Bundle(for: Apptentive.self)
    #else
        static let module: Bundle = Bundle(for: Apptentive.self)
    #endif
}
