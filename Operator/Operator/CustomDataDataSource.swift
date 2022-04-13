//
//  CustomDataDataSource.swift
//  Operator
//
//  Created by Frank Schmitt on 3/22/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import Foundation

protocol CustomDataDataSourceDelegate: AnyObject {
    var customData: CustomData { get set }
}

class CustomDataDataSource: DataDataSource {
    weak var delegate: CustomDataDataSourceDelegate?

    override var customData: CustomData {
        get {
            return self.delegate?.customData ?? CustomData()
        }
        set {
            self.delegate?.customData = newValue
        }
    }
}
