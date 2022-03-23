//
//  EventsViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class EventsViewController: UITableViewController, UITextFieldDelegate {

    
    private static let eventsKey = "Events"
    private static let eventsDictKey = "EventsDict"
    
    private var events: [String]! {
        didSet {
            
            UserDefaults.standard.setValue(self.events, forKey: Self.eventsKey)
        }
    }
    
    private var eventsDict = [String: OperatorEventCustomData]() {
    didSet {
        do {
           let data = try JSONEncoder().encode(eventsDict)
            UserDefaults.standard.set(data, forKey: Self.eventsDictKey)
            } catch {
            print("Encoding error: \(error)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.events = UserDefaults.standard.array(forKey: Self.eventsKey) as? [String] ?? []
       
        do {
            if let data = UserDefaults.standard.data(forKey: Self.eventsDictKey){
            let eventDict = try JSONDecoder().decode([String:OperatorEventCustomData].self, from: data)
            self.eventsDict = eventDict
        }
        } catch {
            print("Error decoding event custom data dictionary: \(error)")
        }
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        NotificationCenter.default.addObserver(self, selector: #selector(eventEngaged), name: Notification.Name.apptentiveEventEngaged, object:nil)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.reloadSections(IndexSet(integer: 0), with: .bottom)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "Event", for: indexPath) as? EventCell else {return UITableViewCell()}
            cell.eventName.text = self.events[indexPath.row]
            cell.eventName.font = .preferredFont(forTextStyle: .headline)
            let eventCustomData = self.eventsDict[self.events[indexPath.row]]
            var customDataString = ""
            
            if eventCustomData?.stringKey != nil || eventCustomData?.numberKey != nil || eventCustomData?.boolKey != nil {
                customDataString = "\nCustom Data:"
            }
            
            if let stringKey = eventCustomData?.stringKey,
               let stringValue = eventCustomData?.stringValue {
                customDataString.append("\nKey: \(stringKey), Value: \(stringValue)")
          }
            if let numberkey = eventCustomData?.numberKey,
               let value = eventCustomData?.numberValue {
                let valueInt = Int(value)
                customDataString.append("\nKey: \(numberkey), Value: \(valueInt)")
        }
        
            if let boolKey = eventCustomData?.boolKey,
               let boolValue = eventCustomData?.boolValue{
                customDataString.append("\nKey: \(boolKey), Value: \(boolValue)")
        }
            cell.customData.text = customDataString
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
            
            var operatorCustomData = OperatorEventCustomData()
                
                
            if let key = cell.stringKeyTextField.text,
               let value = cell.stringValueTextField.text,
                !key.isEmpty,
                !value.isEmpty {
                operatorCustomData.stringKey = key
                operatorCustomData.stringValue = value
            }
            if let key = cell.numberKeyTextField.text,
                let value = cell.numberValueTextField.text,
                    !key.isEmpty,
                      !value.isEmpty,
                let valueInt = Int(value) {
                operatorCustomData.numberKey = key
                operatorCustomData.numberValue = valueInt
            }
            
                if let key = cell.boolKeyTextField.text,
                          !key.isEmpty {
                let value = cell.boolValueSwitch.isOn
                    operatorCustomData.boolKey = key
                    operatorCustomData.boolValue = value
            }
                
                self.eventsDict[newEvent] = operatorCustomData
                self.events.append(newEvent)
                tableView.insertRows(at: [indexPath], with: .bottom)
                self.tableView.tableFooterView = nil
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
            let eventString = self.events[indexPath.row]
            if let eventCustomData = self.eventsDict[eventString] {

                var event = Event(name: eventString)
                
                
                if let key = eventCustomData.stringKey,
                   let value = eventCustomData.stringValue {
                    event.customData[key] = value
            }
                if let key = eventCustomData.numberKey,
                   let value = eventCustomData.numberValue {
                    let valueInt = Int(value)
                    event.customData[key] = valueInt
            }
            
                if let key = eventCustomData.boolKey,
                   let value = eventCustomData.boolValue{
                    event.customData[key] = value
            }
                
                
            self.apptentive.engage(event:event , from: self)
        }
    }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func eventEngaged(notification: Notification) {
        if let eventName = notification.userInfo?["eventType"] {
        print("Event engaged: \(eventName)")
    }
  }
}

struct OperatorEventCustomData: Codable {
    var stringKey: String?
    var stringValue: String?
    var numberKey: String?
    var numberValue: Int?
    var boolKey:String?
    var boolValue: Bool?
}

