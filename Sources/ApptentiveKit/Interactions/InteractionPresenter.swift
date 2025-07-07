//
//  InteractionPresenter.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// An `InteractionPresenter` is used by the Apptentive SDK to present UI represented by `Interaction`  objects to the user.
@MainActor open class InteractionPresenter {
    /// A view controller that can be used to present view-controller-based interactions.
    weak var presentingViewController: UIViewController?
    weak var presentedViewController: UIViewController?

    var presentedInteraction: Interaction?

    var delegate: InteractionDelegate?

    /// Creates a new default interaction presenter.
    public init() {}

    /// Presents an interaction.
    /// - Parameters:
    ///   - interaction: The interaction to present.
    ///   - presentingViewController: The view controller to use to present the interaction.
    /// - Throws: An error if the presentation fails.
    func presentInteraction(_ interaction: Interaction, from presentingViewController: UIViewController? = nil) async throws {
        guard let delegate = self.delegate else {
            throw ApptentiveError.internalInconsistency
        }

        if let presentingViewController = presentingViewController {
            self.presentingViewController = presentingViewController
        }

        switch interaction.configuration {
        case .appleRatingDialog:
            try await AppleRatingDialogController(interaction: interaction, delegate: delegate).requestReview()

        case .enjoymentDialog(let configuration):
            let viewModel = DialogViewModel(configuration: configuration, interaction: interaction, interactionDelegate: delegate)
            try await self.presentEnjoymentDialog(with: viewModel)

        case .navigateToLink(let configuration):
            let controller = NavigateToLinkController(configuration: configuration, interaction: interaction, interactionDelegate: delegate)
            if let viewController = await controller.navigateToLink() {
                try await self.presentViewController(viewController)
                controller.launch(success: true)
            }

        case .textModal(let configuration):
            let viewModel = DialogViewModel(configuration: configuration, interaction: interaction, interactionDelegate: delegate)
            try await self.presentTextModal(with: viewModel)

        case .messageCenter(let configuration):
            let viewModel = MessageCenterViewModel(configuration: configuration, interaction: interaction, interactionDelegate: delegate)
            try await self.presentMessageCenter(with: viewModel)

        case .surveyV12(let configuration):
            let viewModel = SurveyViewModel(configuration: configuration, interaction: interaction, interactionDelegate: delegate)
            try await self.presentSurvey(with: viewModel)

        case .initiator:
            self.launchInitiator(interaction: interaction)

        case .notImplemented:
            throw InteractionPresenterError.notImplemented(interaction.typeName, interaction.id)

        case .failedDecoding:
            throw InteractionPresenterError.decodingFailed(interaction.typeName, interaction.id)
        }

        self.presentedInteraction = interaction
    }

    /// Presents a Message Center Interaction.
    ///
    /// Override this method to change the way Message Center is presented, such as to use a custom view controller.
    /// - Parameter viewModel: the message center view model that represents the message center and handles sending and receiving messages.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`.
    open func presentMessageCenter(with viewModel: MessageCenterViewModel) async throws {

        let messageViewController = MessageCenterViewController(viewModel: viewModel)

        let navigationController = ApptentiveNavigationController(rootViewController: messageViewController)

        try await self.presentViewController(navigationController)
        viewModel.launch()
    }

    /// Presents a Survey interaction.
    ///
    /// Override this method to change the way Surveys are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the survey view model that represents the survey and handles submissions.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`.
    open func presentSurvey(with viewModel: SurveyViewModel) async throws {
        let viewController = SurveyViewController(viewModel: viewModel)

        let navigationController = ApptentiveNavigationController(rootViewController: viewController)

        try await self.presentViewController(navigationController)
        viewModel.launch()
    }

    /// Presents an EnjoymentDialog ("Love Dialog") interaction.
    ///
    /// Override this method to change the way that love dialogs are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the dialog view model that represents the love dialog and handles button taps.
    /// - Throws: Default behavior is to rethrow errors encountered when calling `present(_:)`.
    open func presentEnjoymentDialog(with viewModel: DialogViewModel) async throws {
        let viewController = EnjoymentDialogViewController(viewModel: viewModel)

        try await self.presentViewController(viewController)
        viewModel.launch()
    }

    /// Presents a TextModal ("Note") interaction.
    ///
    /// Override this method to change the way that notes are presented, such as to use a custom view controller.
    /// - Parameter viewModel: the dialog view model that represents the note and handles button taps.
    /// - Throws: an error if the presentation fails
    open func presentTextModal(with viewModel: DialogViewModel) async throws {
        let viewController = TextModalViewController(viewModel: viewModel)

        await viewModel.prepareForPresentation()
        try await self.presentViewController(viewController)
        viewModel.launch()
    }

    /// Presents a view-controller-based interaction.
    ///
    /// Override this method to change the way interactions are presented.
    ///
    /// - Parameters:
    ///  - viewControllerToPresent: the interaction view controller that should be presented.
    /// - Throws: if the `presentingViewController` property is nil or has an unrecoverable issue.
    open func presentViewController(_ viewControllerToPresent: UIViewController) async throws {
        guard let presentingViewController = self.validatedPresentingViewController else {
            throw InteractionPresenterError.noPresentingViewController
        }

        if viewControllerToPresent is DialogViewController {
            viewControllerToPresent.modalPresentationStyle = .overFullScreen
            viewControllerToPresent.modalTransitionStyle = .crossDissolve
        } else {
            viewControllerToPresent.modalPresentationStyle = .apptentive
        }

        await withCheckedContinuation { continuation in
            presentingViewController.present(viewControllerToPresent, animated: true) {
                continuation.resume()
            }
        }

        self.presentedViewController = viewControllerToPresent
    }

    /// Checks the `presentingViewController` property and recovers from common failure modes.
    public var validatedPresentingViewController: UIViewController? {
        // Fall back to the crawling the window's VC hierachy if certain failures exist.
        // TODO: make sure this works with scene-based apps.
        if self.presentingViewController == nil || self.presentingViewController?.isViewLoaded == false || self.presentingViewController?.view.window == nil {
            let rootViewController = UIApplication.shared.firstActiveScene?.keyWindow?.rootViewController
            self.presentingViewController = UIViewController.topViewController(controller: rootViewController)
        }

        // If we have a presenting view but one of its ancestors' `isBeingDismissed` is set, use that VC's parent.
        if let presentingViewController = self.presentingViewController,
            let dismissingAncestor = Self.findDismissingAncestor(of: presentingViewController),
            let parentOfDismissingAncestor = Self.findParentViewController(of: dismissingAncestor)
        {
            return parentOfDismissingAncestor
        } else {
            // Otherwise, as far as we know, the presenting view controller is good.
            return presentingViewController
        }
    }

    /// Checks if Message Center is currently displayed.
    public var messageCenterCurrentlyPresented: Bool {
        if let apptentiveNavigationController = self.presentedViewController as? ApptentiveNavigationController,
            let rootViewController = apptentiveNavigationController.viewControllers.first
        {
            return rootViewController is MessageCenterViewController
        } else {
            return false
        }
    }

    open func dismissPresentedViewController(animated: Bool) {
        self.presentedViewController?.dismiss(animated: animated)

        var dismissEvent = Event.cancel(from: self.presentedInteraction)
        dismissEvent.userInfo = .dismissCause(.init(cause: "notification"))

        self.delegate?.engage(event: dismissEvent)
    }

    private func launchInitiator(interaction: Interaction) {
        self.delegate?.engage(event: .launch(from: interaction))
    }

    /// Walks up the view controller hierarchy to find any ancestors that are being dismissed, and returns that ancestor's parent, or nil if no parents are being dismissed.
    /// - Parameter viewController: The view controller whose parents should be checked for "is being dismissed" status.
    /// - Returns: The parent of the view controller that is being dismissed, if one exists that is an ancestor of `viewController`.
    private static func findDismissingAncestor(of viewController: UIViewController) -> UIViewController? {
        if viewController.isBeingDismissed {
            return viewController
        } else if let parent = Self.findParentViewController(of: viewController) {
            return findDismissingAncestor(of: parent)
        } else {
            return nil
        }
    }

    /// Finds the next UIViewController subclass in the responder chain starting with the specified responder.
    /// - Parameter responder: The responder at which to start searching.
    /// - Returns: The next UIViewController subclass in the responder chain, if one exists.
    private static func findParentViewController(of responder: UIResponder) -> UIViewController? {
        guard let next = responder.next else {
            return nil  // Responder chain is broken, or we've reached the end.
        }

        if let viewController = next as? UIViewController {
            return viewController
        } else {
            return findParentViewController(of: next)
        }
    }
}

/// An error that occurs while presenting an interaction.
public enum InteractionPresenterError: Error, Equatable {
    case notImplemented(String, String)
    case decodingFailed(String, String)
    case noPresentingViewController
}

struct CancelInteractionCause: Codable, Equatable {
    let cause: String
}

extension UIViewController {
    class func topViewController(controller: UIViewController?) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}

// Courtesy of https://sarunw.com/posts/how-to-get-root-view-controller/
extension UIApplication {
    var firstActiveScene: UIWindowScene? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .first
    }
}
