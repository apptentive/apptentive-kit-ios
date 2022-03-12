//
//  DeviceDataSource.swift
//  Operator
//
//  Created by Frank Schmitt on 2/17/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class DeviceDataSource: DataDataSource {
    override var customData: CustomData {
        get {
            return self.apptentive.deviceCustomData
        }
        set {
            self.apptentive.deviceCustomData = newValue
        }
    }
}
