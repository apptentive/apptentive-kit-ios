//
//  ViewController.swift
//  ApptentiveUITestsApp
//
//  Created by Apptentive on 3/3/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

struct TestRow {
    var label: String
    var action: () -> Void
}

class ViewController: UITableViewController {
    private var rows = [TestRow]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.rows = [
            TestRow(label: "Present Love Dialog with Configuration", action: self.presentLoveDialogWithConfiguration),
        ]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = self.rows[indexPath.row].label

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        self.rows[indexPath.row].action()
    }
}

extension ViewController {

    fileprivate func presentLoveDialogWithConfiguration() {

        let apptentive = Apptentive()
        let configuration = LoveDialogConfiguration(affirmativeText: "Yup", negativeText: "")
        apptentive.presentLoveDialog(from: self, with: configuration)
    }
}
