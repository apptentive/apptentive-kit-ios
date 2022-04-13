//
//  CustomDataViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 3/22/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

import ApptentiveKit
import UIKit

class CustomDataViewController: UITableViewController {
    var dataSource: CustomDataDataSource?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem

        self.tableView.dataSource = self.dataSource
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let dataSource = self.tableView.dataSource as! DataDataSource

        tableView.beginUpdates()

        dataSource.setEditing(editing, for: tableView)

        tableView.endUpdates()

        super.setEditing(editing, animated: animated)
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        let dataSource = tableView.dataSource as! DataDataSource

        return dataSource.editingStyleForRow(at: indexPath)
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        let dataSource = tableView.dataSource as! DataDataSource

        return dataSource.shouldIndentWhileEditingRow(at: indexPath)
    }
}
