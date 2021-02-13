//
//  DataTableViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 2/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit
import ApptentiveKit

class DataTableViewController: UITableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                self.apptentive.personCustomData["string"] = "foo"

            case 1:
                self.apptentive.personCustomData["number"] = 42

            case 2:
                self.apptentive.personCustomData["bool"] = true

            case 3:
                self.apptentive.personName = "Testy McTestface"

            case 4:
                self.apptentive.personEmailAddress = "test@example.com"

            default:
                self.apptentive.personCustomData["string"] = nil
                self.apptentive.personCustomData["number"] = nil
                self.apptentive.personCustomData["bool"] = nil
                self.apptentive.personName = nil
                self.apptentive.personEmailAddress = nil
            }
        default:
            switch indexPath.row {
            case 0:
                self.apptentive.deviceCustomData["string"] = "foo"

            case 1:
                self.apptentive.deviceCustomData["number"] = 42

            case 2:
                self.apptentive.deviceCustomData["bool"] = true

            default:
                self.apptentive.deviceCustomData["string"] = nil
                self.apptentive.deviceCustomData["number"] = nil
                self.apptentive.deviceCustomData["bool"] = nil
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }


}
