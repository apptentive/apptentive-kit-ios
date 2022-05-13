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
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.manifestURLs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "manifest", for: indexPath)

        cell.textLabel?.text = self.manifestURLs[indexPath.row].deletingPathExtension().lastPathComponent

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedManifestURL = self.manifestURLs[indexPath.row]

        self.apptentive.loadEngagementManifest(at: selectedManifestURL)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.apptentive.loadEngagementManifest(at: nil)
    }

    @IBAction func dismiss() {
        self.apptentive.loadEngagementManifest(at: nil)

        self.dismiss(animated: true)
    }

    @IBAction func launch() {
        self.apptentive.engage(event: "launch")
    }

    private func loadManifestURLs() {
        guard let interactionsDirectoryURL = Bundle.main.url(forResource: "Manifests", withExtension: "") else {
            return assertionFailure("Can't find bundled manifests")
        }

        do {
            self.manifestURLs = try FileManager.default.contentsOfDirectory(at: interactionsDirectoryURL, includingPropertiesForKeys: nil, options: [])
        } catch let error {
            assertionFailure("Error loading bundled manifests: \(error)")
        }
    }
}
