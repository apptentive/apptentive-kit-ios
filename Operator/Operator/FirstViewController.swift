//
//  FirstViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 4/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class FirstViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func love(_ sender: Any) {
        apptentive.presentLoveDialog(from: self, with: LoveDialogConfiguration())
    }

    @IBAction func survey(_ sender: Any) {
        guard let surveyURL = Bundle.main.url(forResource: "Survey", withExtension: "json"),
              let surveyData = try? Data(contentsOf: surveyURL)
        else {
            return print("Unable to find test survey data")
        }

        guard let surveyInteraction = try? JSONDecoder().decode(Interaction.self, from: surveyData) else {
            return print("Unable to decode test survey data")
        }

        apptentive.presentInteraction(surveyInteraction, from: self)
    }
}
