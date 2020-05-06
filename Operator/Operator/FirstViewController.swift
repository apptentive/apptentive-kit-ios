//
//  FirstViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 4/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit
import ApptentiveKit

class FirstViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	@IBAction func love(_ sender: Any) {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let apptentive = appDelegate.apptentive else {
			return
		}

		apptentive.presentLoveDialog(from: self, with: LoveDialogConfiguration())
	}
}

