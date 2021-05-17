//
//  CustomCells.swift
//  Operator
//
//  Created by Frank Schmitt on 2/17/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class AddDataCell: UITableViewCell {
    @IBOutlet var keyTextField: UITextField!
}

class AddStringCell: AddDataCell {
    @IBOutlet var stringTextField: UITextField!
}

class AddNumberCell: AddDataCell {
    @IBOutlet var numberTextField: UITextField!
}

class AddBooleanCell: AddDataCell {
    @IBOutlet var booleanSwitch: UISwitch!
}

class EditStringCell: UITableViewCell {
    @IBOutlet var stringTextField: UITextField!
}
