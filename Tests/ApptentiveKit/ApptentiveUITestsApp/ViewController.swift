//
//  ViewController.swift
//  ApptentiveUITestsApp
//
//  Created by Frank Schmitt on 3/3/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

struct TestRow {
    var label: String
    var action: () -> Void
}

class ViewController: UITableViewController {
    var interactions = [Apptentive.InteractionListItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadInteractions()
        //TODO: Set header here in order to test it.
        //UIImage.apptentiveHeaderLogo = UIImage(named: "exampleLogo")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.interactions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Interaction", for: indexPath)

        cell.textLabel?.text = self.interactions[indexPath.row].displayName

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Apptentive.shared.presentInteraction(with: self.interactions[indexPath.row].id) { _ in }

        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    private func loadInteractions() {
        guard let manifestURL = Bundle.main.url(forResource: "Manifest", withExtension: "json") else {
            return assertionFailure("Can't find bundled interactions")
        }

        Apptentive.shared.loadEngagementManifest(at: manifestURL) { _ in
            Apptentive.shared.getInteractionList({ interactions in
                self.interactions = interactions

                self.tableView.reloadData()
            })
        }
    }
}
