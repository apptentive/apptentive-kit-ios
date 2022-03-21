//
//  AddEventCell.swift
//  Operator
//
//  Created by Frank Schmitt on 9/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class AddEventCell: UITableViewCell {
    
    @IBOutlet var textField: UITextField!
    @IBOutlet weak var stringKeyTextField: UITextField!
    @IBOutlet weak var boolKeyTextField: UITextField!
    @IBOutlet weak var numberKeyTextField: UITextField!
    @IBOutlet weak var numberValueTextField: UITextField!
    @IBOutlet weak var stringValueTextField: UITextField!
    @IBOutlet weak var boolValueSwitch: UISwitch!
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            self.textField.becomeFirstResponder()
        } else {
            self.textField.resignFirstResponder()
        }
    }
   
}
