//
//  EventsViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class EventsViewController: UITableViewController {
    private static let eventsKey = "Events"

    private var events: [String]! {
        didSet {
            UserDefaults.standard.setValue(self.events, forKey: Self.eventsKey)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.events = UserDefaults.standard.array(forKey: Self.eventsKey) as? [String] ?? []

        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.tableView.reloadSections(IndexSet(integer: 0), with: .bottom)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isEditing {
            return self.events.count + 1
        } else {
            return self.events.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == self.events.count {
            return tableView.dequeueReusableCell(withIdentifier: "Add Event", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath)

            cell.textLabel?.text = self.events[indexPath.row]

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.events.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            let cell = tableView.cellForRow(at: indexPath) as! AddEventCell

            if let newEvent = cell.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), newEvent.count > 0 {
                self.events.append(newEvent)
                tableView.insertRows(at: [indexPath], with: .bottom)
            }
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        indexPath.row < self.events.count ? .delete : .insert
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        self.events.insert(self.events.remove(at: fromIndexPath.row), at: to.row)
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row < self.events.count
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.isEditing {
            self.apptentive.engage(event: Event(name: self.events[indexPath.row]), from: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
