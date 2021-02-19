//
//  PersonDataSource.swift
//  Operator
//
//  Created by Frank Schmitt on 2/17/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit
import ApptentiveKit

class PersonDataSource: DataDataSource {
    override var customData: CustomData {
        get {
            return self.apptentive.personCustomData
        }
        set {
            self.apptentive.personCustomData = newValue
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        } else {
            return 2
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return super.tableView(tableView, titleForHeaderInSection: section)
        } else {
            return "Standard Data"
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return super.tableView(tableView, cellForRowAt: indexPath)
        } else {
            let (key, value, keyboardType): (String, String?, UIKeyboardType) = {
                switch indexPath.row {
                case 0:
                    return ("Name", self.apptentive.personName, .default)

                default:
                    return ("Email", self.apptentive.personEmailAddress, .emailAddress)
                }
            }()

            if self.isEditing {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Edit String", for: indexPath) as! EditStringCell

                cell.stringTextField.placeholder = key
                cell.stringTextField.text = value
                cell.stringTextField.keyboardType = keyboardType
                cell.stringTextField.tag = indexPath.row
                cell.stringTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)

                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Display", for: indexPath)

                cell.textLabel?.text = key
                cell.detailTextLabel?.text = value ?? "Not Set"
                cell.detailTextLabel?.textColor = value == nil ? UIColor.apptentiveSecondaryLabel : UIColor.apptentiveLabel

                return cell
            }
        }
    }

    override func editingStyleForRow(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 0 {
            return super.editingStyleForRow(at: indexPath)
        } else {
            return .none
        }
    }

    override func shouldIndentWhileEditingRow(at indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return super.shouldIndentWhileEditingRow(at: indexPath)
        } else {
            return false
        }
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        switch sender.tag {
        case 0:
            self.apptentive.personName = sender.text

        case 1:
            self.apptentive.personEmailAddress = sender.text

        default:
            fatalError("Unknown text field tag for standard person data")
        }
    }
}
