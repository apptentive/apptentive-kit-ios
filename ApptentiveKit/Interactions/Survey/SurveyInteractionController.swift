//
//  SurveyInteractionController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/2/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation
import UIKit

class SurveyInteractionController: NSObject, UIAdaptivePresentationControllerDelegate {
    let interaction: Interaction
    var retainer: SurveyInteractionController?  // Allow creating (intentional) retain cycle

    private var surveyViewController: SurveyViewController?

    init(interaction: Interaction) {
        self.interaction = interaction

        super.init()

        self.retainer = self
    }

    lazy var viewModel: SurveyViewModel = SurveyViewModel(interaction: self.interaction)

    lazy var viewController: UIViewController = {
        let surveyViewController = SurveyViewController(viewModel: self.viewModel)
        let navigationController = UINavigationController(rootViewController: surveyViewController)

        surveyViewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss))
        self.surveyViewController = surveyViewController

        return navigationController
    }()

    func present(from presentingViewController: UIViewController) {
        presentingViewController.present(self.viewController, animated: true) {
            self.viewController.presentationController?.delegate = self
        }
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.retainer = nil
    }

    @objc func dismiss(_ sender: Any) {
        self.viewController.dismiss(
            animated: true,
            completion: {
                self.retainer = nil
            })
    }
}

struct SurveyError: Error {}
