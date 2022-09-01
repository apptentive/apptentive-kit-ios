//
//  EventsViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class EventsViewController: UITableViewController, CustomDataDataSourceDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.customEvents = UserDefaults.standard.array(forKey: Self.eventsKey) as? [String] ?? []
        self.underlyingCustomData = UserDefaults.standard.dictionary(forKey: Self.customDataKey) ?? [:]

        for (key, value) in self.underlyingCustomData {
            switch value {
            case let stringValue as String:
                self.customData[key] = stringValue

            case let intValue as Int:
                self.customData[key] = intValue

            case let doubleValue as Double:
                self.customData[key] = doubleValue

            case let boolValue as Bool:
                self.customData[key] = boolValue

            default:
                break
            }
        }

        self.navigationItem.rightBarButtonItem = self.editButtonItem

        NotificationCenter.default.addObserver(self, selector: #selector(eventEngaged), name: Notification.Name.apptentiveEventEngaged, object:nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.loadEvents()

        self.updatePrompt()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        self.tableView.reloadSections(IndexSet(integer: 0), with: .bottom)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowEventCustomData" {
            guard let customDataViewController = segue.destination as? CustomDataViewController else {
                fatalError("Custom data segue should lead to custom data view controller")
            }

            let dataSource = CustomDataDataSource(self.apptentive)
            dataSource.customData = self.customData
            dataSource.delegate = self

            customDataViewController.dataSource = dataSource
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if self.isEditing {
                return self.customEvents.count + 1
            } else {
                return self.customEvents.count
            }
        } else {
            return self.manifestEvents.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if indexPath.row == self.customEvents.count {
                return tableView.dequeueReusableCell(withIdentifier: "Add Event", for: indexPath)
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath)

                cell.textLabel?.text = self.customEvents[indexPath.row]

                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath)

            cell.textLabel?.text = self.manifestEvents[indexPath.row]

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.customEvents.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            let cell = tableView.cellForRow(at: indexPath) as! AddEventCell

            if let newEvent = cell.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), newEvent.count > 0 {
                self.customEvents.append(newEvent)
                tableView.insertRows(at: [indexPath], with: .bottom)
            }
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        indexPath.row < self.customEvents.count ? .delete : .insert
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        self.customEvents.insert(self.customEvents.remove(at: fromIndexPath.row), at: to.row)
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && indexPath.row < self.customEvents.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Custom Events"
        } else {
            return "Targeted Events"
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !self.isEditing {
            var event = indexPath.section == 0 ? Event(name: self.customEvents[indexPath.row]) : Event(name: self.manifestEvents[indexPath.row])

            if self.customData.keys.count > 0 {
                event.customData = self.customData
            }

            self.apptentive.engage(event: event, from: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - Actions

    @IBAction func reload(_ sender: UIBarButtonItem) {
        self.loadEvents()
    }

    // MARK: - Notifications
    
    @objc func eventEngaged(notification: Notification) {
        if let eventName = notification.userInfo?["eventType"] {
            print("Event engaged: \(eventName)")
        }
    }

    // MARK: - Internal

    internal var customData = CustomData() {
        didSet {
            for key in self.customData.keys {
                self.underlyingCustomData[key] = self.customData[key]
            }

            for removedKey in Set(self.customData.keys).subtracting(self.customData.keys) {
                self.underlyingCustomData.removeValue(forKey: removedKey)
            }
        }
    }

    // MARK: - Private

    private static let eventsKey = "Events"
    private static let customDataKey = "EventCustomData"

    private func updatePrompt() {
        if let manifestOverride = self.apptentive.engagementManifestURL?.lastPathComponent {
            self.navigationItem.prompt = "Using “\(manifestOverride)” Manifest"
        } else {
            self.navigationItem.prompt = nil
        }
    }

    private var underlyingCustomData = [String: Any]() {
        didSet {
            UserDefaults.standard.set(self.underlyingCustomData, forKey: Self.customDataKey)
        }
    }

    private var customEvents: [String]! {
        didSet {
            UserDefaults.standard.setValue(self.customEvents, forKey: Self.eventsKey)
        }
    }

    private var manifestEvents = [String]()

    private func loadEvents() {
        self.apptentive.getEventList { events in
            self.manifestEvents = events

            self.tableView.reloadData()
        }
    }
}
