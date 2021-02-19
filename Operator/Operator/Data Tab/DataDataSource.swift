//
//  DataDataSource.swift
//  Operator
//
//  Created by Frank Schmitt on 2/17/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit
import ApptentiveKit

class DataDataSource: NSObject, UITableViewDataSource {
    var isEditing = false
    let apptentive: Apptentive
    static let editRowReuseIdentifiers = ["Add String", "Add Number", "Add Boolean"]

    init(_ apptentive: Apptentive) {
        self.apptentive = apptentive
        super.init()
    }

    func setEditing(_ editing: Bool, for tableView: UITableView) {
        let wasEditing = isEditing

        let editIndexPaths = (0..<Self.editRowReuseIdentifiers.count).map {
            return IndexPath(row: self.keys.count + $0, section: 0)
        }

        tableView.beginUpdates()

        self.isEditing = editing

        if editing && !wasEditing {
            tableView.insertRows(at: editIndexPaths, with: .automatic)
        } else if !editing && wasEditing {
            tableView.deleteRows(at: editIndexPaths, with: .automatic)
        }

        tableView.endUpdates()
    }

    var customData: CustomData {
        get {
            fatalError("Attempting to call abstract method")
        }
        set {
            fatalError("Attempting to call abstract method")
        }
    }

    var keys: [String] {
        return self.customData.keys.sorted()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isEditing {
            return Self.editRowReuseIdentifiers.count + self.keys.count
        } else {
            return max(self.keys.count, 1)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.isEditing && indexPath.row >= self.keys.count {
            let editRowIndex = indexPath.row - self.keys.count
            return tableView.dequeueReusableCell(withIdentifier: Self.editRowReuseIdentifiers[editRowIndex], for: indexPath)
        } else if indexPath.row < self.keys.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Display", for: indexPath)

            let key = self.keys[indexPath.row]
            let value: String = {
                switch self.customData[key] {
                case let string as String:
                    return string

                case let bool as Bool:
                    return bool ? "true" : "false"

                case let int as Int:
                    return String(int)

                case let double as Double:
                    return String(double)

                default:
                    return "<Unkown Type>"
                }
            }()

            cell.textLabel?.text = key
            cell.detailTextLabel?.text = value

            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Empty State", for: indexPath)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Custom Data"
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row < self.keys.count && editingStyle == .delete {
            self.customData[self.keys[indexPath.row]] = nil
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } else {
            let cell = tableView.cellForRow(at: indexPath) as! AddDataCell
            let key = cell.keyTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if key == "" {
                return
            }

            switch cell {
            case let cell as AddStringCell:
                self.customData[key] = cell.stringTextField.text

            case let cell as AddNumberCell:
                self.customData[key] = Double(cell.numberTextField.text ?? "")

            case let cell as AddBooleanCell:
                self.customData[key] = cell.booleanSwitch.isOn

            default:
                fatalError("Unexpected row for editing custom data")
            }

            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }

    func editingStyleForRow(at indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row < self.keys.count {
            return .delete
        } else {
            return .insert
        }
    }

    func shouldIndentWhileEditingRow(at indexPath: IndexPath) -> Bool {
        return true
    }
}
