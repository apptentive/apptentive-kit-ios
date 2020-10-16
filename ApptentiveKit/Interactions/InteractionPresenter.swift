//
//  InteractionPresenter.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// An `InteractionPresenter` is used by the Apptentive SDK to present UI represented by `Interaction`  objects to the user.
open class InteractionPresenter {
    /// A view controller that can be used to present view-controller-based interactions.
    open var presentingViewController: UIViewController?

    var sender: ResponseSending?

    /// Creates a new default interaction presenter.
    public init() {}

    /// Presents an interaction.
    /// - Parameters:
    ///   - interaction: The interaction to present.
    ///   - presentingViewController: The view controller to use to present the interaction.
    /// - Throws: If the `sender` property isn't set, if the interaction isn't recognized, or if the presenting view controller is missing or invalid.
    func presentInteraction(_ interaction: Interaction, from presentingViewController: UIViewController? = nil) throws {
        guard let sender = self.sender else {
            throw ApptentiveError.internalInconsistency
        }

        if let presentingViewController = presentingViewController {
            self.presentingViewController = presentingViewController
        }

        switch interaction.configuration {
        case .survey(let surveyConfiguration):
            let viewModel = SurveyViewModel(configuration: surveyConfiguration, surveyID: interaction.id, sender: sender)
            try self.presentSurvey(with: viewModel)
        default:
            throw InteractionPresenterError.notImplemented(interaction.typeName)
        }
    }

    /// Presents a Survey interaction.
    ///
    /// Override this method to change the way Surveys are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the survey view model that represents the survey and handles submissions.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`
    open func presentSurvey(with viewModel: SurveyViewModel) throws {
        let viewController = SurveyViewController(viewModel: viewModel)

        let navigationController = UINavigationController(rootViewController: viewController)

        try self.presentViewController(navigationController)
    }

    /// Presents a view-controller-based interaction.
    ///
    /// Override this method to change the way interactions are presented.
    ///
    /// - Parameter viewControllerToPresent: the interaction view controller that should be presented.
    /// - Throws: if the `presentingViewController` property is nil or does not reference a view controller that can currently present another view controller.
    open func presentViewController(_ viewControllerToPresent: UIViewController) throws {
        guard let presentingViewController = self.presentingViewController else {
            throw InteractionPresenterError.noPresentingViewController
        }

        guard let _ = presentingViewController.view.window else {
            throw InteractionPresenterError.presentingViewControllerNotInWindow
        }

        guard presentingViewController.isViewLoaded else {
            throw InteractionPresenterError.presentingViewControllerViewNotLoaded
        }

        presentingViewController.present(viewControllerToPresent, animated: true)
    }
}

/// An error that occurs while presenting an interaction.
public enum InteractionPresenterError: Error {
    case notImplemented(String)
    case noPresentingViewController
    case presentingViewControllerNotInWindow
    case presentingViewControllerViewNotLoaded
}
