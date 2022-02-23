//
//  InteractionsViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 7/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class InteractionsViewController: UITableViewController {
    var interactions = [(String, Interaction)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadInteractions()
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
        cell.textLabel?.text = self.interactions[indexPath.row].0
        cell.detailTextLabel?.text = self.interactions[indexPath.row].1.typeName

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        try? self.apptentive.presentInteraction(self.interactions[indexPath.row].1, from: self)

        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    private func loadInteractions() {
        guard let interactionsDirectoryURL = Bundle.main.url(forResource: "Interactions", withExtension: "") else {
            return assertionFailure("Can't find bundled interactions")
        }

        self.interactions.removeAll()

        do {
            let interactionsFiles = try FileManager.default.contentsOfDirectory(at: interactionsDirectoryURL, includingPropertiesForKeys: nil, options: [])

            let decoder = JSONDecoder()
            interactionsFiles.forEach { (url) in
                do {
                    let interactionData = try Data(contentsOf: url)
                    let interaction = try decoder.decode(Interaction.self, from: interactionData)

                    self.interactions.append((url.deletingPathExtension().lastPathComponent, interaction))
                } catch let error {
                    assertionFailure("Error loading bundled interaction from \(url): \(error)")
                }
            }
        } catch let error {
            assertionFailure("Error loading bundled interactions: \(error)")
        }
    }
}
