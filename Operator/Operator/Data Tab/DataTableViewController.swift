//
//  DataTableViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 2/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class DataTableViewController: UITableViewController {
    @IBOutlet var modeControl: UISegmentedControl!
    var dataSources: [DataDataSource] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem

        self.dataSources = [
            PersonDataSource(self.apptentive),
            DeviceDataSource(self.apptentive),
        ]

        self.tableView.dataSource = self.dataSources[self.modeControl.selectedSegmentIndex]
    }

    @IBAction func changeMode(_ sender: UISegmentedControl) {
        let toIndex = sender.selectedSegmentIndex
        let fromIndex = (1 + toIndex) % 2

        let toDataSource = self.dataSources[toIndex]
        let fromDataSource = self.dataSources[fromIndex]

        self.tableView.beginUpdates()

        self.tableView.dataSource = toDataSource

        let difference = toDataSource.numberOfSections(in: self.tableView) - fromDataSource.numberOfSections(in: self.tableView)
        let animation: UITableView.RowAnimation = toIndex == 0 ? .right : .left

        if difference > 0 {
            self.tableView.insertSections(IndexSet(integer: 1), with: animation)
        } else if difference < 0 {
            self.tableView.deleteSections(IndexSet(integer: 1), with: animation)
        }

        self.tableView.reloadSections(IndexSet(integer: 0), with: animation)

        self.tableView.endUpdates()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        let dataSource = self.tableView.dataSource as! DataDataSource
        let otherDataSource = dataSources.first(where: { $0 != dataSource })

        tableView.beginUpdates()

        dataSource.setEditing(editing, for: tableView)
        otherDataSource?.isEditing = editing

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
