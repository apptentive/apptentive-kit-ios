//
//  ManifestsViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 5/10/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class ManifestsViewController: UITableViewController {
    var manifestURLs = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadManifestURLs()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return self.manifestURLs.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "manifest", for: indexPath)

        if indexPath.section == 0 {
            cell.textLabel?.text = "Default (from Dashboard)"
            cell.accessoryType = self.selectedIndex == nil ? .checkmark : .none
        } else {
            cell.textLabel?.text = self.manifestURLs[indexPath.row].deletingPathExtension().lastPathComponent
            cell.accessoryType = self.selectedIndex == indexPath.row ? .checkmark : .none
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let selectedIndex = self.selectedIndex {
            tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 1))?.accessoryType = .none
            self.selectedIndex = nil
        } else {
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .none
        }

        var selectedManifestURL: URL?
        if indexPath.section == 0 {
            selectedManifestURL = nil
        } else {
            selectedManifestURL = self.manifestURLs[indexPath.row]
        }

        Task {
            defer {
                tableView.deselectRow(at: indexPath, animated: true)
            }

            try await self.apptentive.loadEngagementManifest(at: selectedManifestURL)
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            self.selectedIndex = indexPath.section == 0 ? nil : indexPath.row

            self.performSegue(withIdentifier: "doneChoosing", sender: self)
        }
    }

    private var selectedIndex: Int?

    private func loadManifestURLs() {
        guard let interactionsDirectoryURL = Bundle.main.url(forResource: "Manifests", withExtension: "") else {
            return assertionFailure("Can't find bundled manifests")
        }

        do {
            self.manifestURLs = try FileManager.default.contentsOfDirectory(at: interactionsDirectoryURL, includingPropertiesForKeys: nil, options: [])

            if let selectedURL = self.apptentive.engagementManifestURL {
                self.selectedIndex = self.manifestURLs.firstIndex(of: selectedURL)
            }
        } catch let error {
            assertionFailure("Error loading bundled manifests: \(error)")
        }
    }
}
