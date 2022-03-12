//
//  TextViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class TextViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var textField: UITextField!

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.performSegue(withIdentifier: "send", sender: self)

        return true
    }
}
