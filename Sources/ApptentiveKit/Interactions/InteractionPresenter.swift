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

    var delegate: InteractionDelegate?

    /// Creates a new default interaction presenter.
    public init() {}

    /// Presents an interaction.
    /// - Parameters:
    ///   - interaction: The interaction to present.
    ///   - presentingViewController: The view controller to use to present the interaction.
    /// - Throws: If the `sender` property isn't set, if the interaction isn't recognized, or if the presenting view controller is missing or invalid.
    func presentInteraction(_ interaction: Interaction, from presentingViewController: UIViewController? = nil) throws {
        guard let delegate = self.delegate else {
            throw ApptentiveError.internalInconsistency
        }

        if let presentingViewController = presentingViewController {
            self.presentingViewController = presentingViewController
        }

        switch interaction.configuration {
        case .appleRatingDialog:
            AppleRatingDialogController(interaction: interaction, delegate: delegate).requestReview()

        case .enjoymentDialog(let configuration):
            let viewModel = EnjoymentDialogViewModel(configuration: configuration, interaction: interaction, delegate: delegate)
            try self.presentEnjoymentDialog(with: viewModel)

        case .navigateToLink(let configuration):
            let controller = NavigateToLinkController(configuration: configuration, interaction: interaction, delegate: delegate)
            controller.navigateToLink()

        case .survey(let configuration):
            let viewModel = SurveyViewModel(configuration: configuration, interaction: interaction, interactionDelegate: delegate)
            try self.presentSurvey(with: viewModel)

        case .textModal(let configuration):
            let viewModel = TextModalViewModel(configuration: configuration, interaction: interaction, delegate: delegate)
            try self.presentTextModal(with: viewModel)

        case .notImplemented:
            let viewModel = NotImplementedAlertViewModel(interactionTypeName: interaction.typeName)
            try self.presentViewController(UIAlertController(viewModel: viewModel))
            throw InteractionPresenterError.notImplemented(interaction.typeName)
        }
    }

    /// Presents an EnjoymentDialog ("Love Dialog") interaction.
    ///
    /// Override this method to change the way that love dialogs are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the love dialog view model that represents the love dialog and handles button taps.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`.
    open func presentEnjoymentDialog(with viewModel: EnjoymentDialogViewModel) throws {
        let viewController = UIAlertController(viewModel: viewModel)

        try self.presentViewController(
            viewController,
            completion: {
                viewModel.launch()
            })
    }

    /// Presents a Survey interaction.
    ///
    /// Override this method to change the way Surveys are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the survey view model that represents the survey and handles submissions.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`.
    open func presentSurvey(with viewModel: SurveyViewModel) throws {
        let viewController = SurveyViewController(viewModel: viewModel)

        let navigationController = ApptentiveNavigationController(rootViewController: viewController)

        try self.presentViewController(
            navigationController,
            completion: {
                viewModel.launch()
            })
    }

    /// Presents a TextModal ("Note") interaction.
    ///
    /// Override this method to change the way that notes are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the love dialog view model that represents the love dialog and handles button taps.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`.
    open func presentTextModal(with viewModel: TextModalViewModel) throws {
        let viewController = UIAlertController(viewModel: viewModel)

        try self.presentViewController(
            viewController,
            completion: {
                viewModel.launch()
            })
    }

    /// Presents a view-controller-based interaction.
    ///
    /// Override this method to change the way interactions are presented.
    ///
    /// - Parameters:
    ///  - viewControllerToPresent: the interaction view controller that should be presented.
    ///  - completion: a closure that is called when the interaction presentation completes.
    /// - Throws: if the `presentingViewController` property is nil or does not reference a view controller that can currently present another view controller.
    open func presentViewController(_ viewControllerToPresent: UIViewController, completion: (() -> Void)? = {}) throws {
        guard let presentingViewController = self.presentingViewController else {
            throw InteractionPresenterError.noPresentingViewController
        }

        guard let _ = presentingViewController.view.window else {
            throw InteractionPresenterError.presentingViewControllerNotInWindow
        }

        guard presentingViewController.isViewLoaded else {
            throw InteractionPresenterError.presentingViewControllerViewNotLoaded
        }

        presentingViewController.present(viewControllerToPresent, animated: true, completion: completion)
    }
}

/// An error that occurs while presenting an interaction.
public enum InteractionPresenterError: Error {
    case notImplemented(String)
    case noPresentingViewController
    case presentingViewControllerNotInWindow
    case presentingViewControllerViewNotLoaded
}
