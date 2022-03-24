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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            self.textField.becomeFirstResponder()
        } else {
            self.textField.resignFirstResponder()
        }
    }
}
