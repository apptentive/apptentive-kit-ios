//
//  SurveyHostingController.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/10/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// A UIViewController that hosts the SwiftUI survey view.
class SurveyHostingController: UIHostingController<SurveyView>, SurveyViewModelDelegate {
    let viewModel: SurveyViewModel

    init(viewModel: SurveyViewModel) {
        self.viewModel = viewModel

        let surveyView = SurveyView(viewModel: viewModel)
        super.init(rootView: surveyView)

        // Set up the view model delegate to handle dismissal and other events
        self.viewModel.delegate = self

        // Configure the view controller
        self.configurePresentationStyle()
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if viewModel.termsAndConditions != nil {
            navigationController?.setToolbarHidden(false, animated: animated)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure navigation bar
        if let headerLogo = UIImage.apptentiveHeaderLogo {
            let headerImageView = UIImageView(image: headerLogo.withRenderingMode(.alwaysOriginal))
            headerImageView.contentMode = .scaleAspectFit
            self.navigationItem.titleView = headerImageView
        } else {
            self.navigationItem.title = viewModel.name
        }

        // Add close button if needed
        if !ApptentiveNavigationController.prefersLargeHeader {
            self.navigationItem.rightBarButtonItem = .apptentiveClose
            self.navigationItem.rightBarButtonItem?.target = self
            self.navigationItem.rightBarButtonItem?.action = #selector(cancelSurvey)
        }

        // Dismiss the keyboard on a tap anywhere outside a text input. `cancelsTouchesInView = false`
        // lets the tap still reach whatever was tapped (choices, buttons, range control, links).
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        dismissKeyboardTap.cancelsTouchesInView = false
        dismissKeyboardTap.delegate = self
        view.addGestureRecognizer(dismissKeyboardTap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    override var isModalInPresentation: Bool {
        get {
            return viewModel.shouldConfirmCancel
        }
        set {}
    }

    private func configurePresentationStyle() {
        // Match the UIKit implementation's presentation style
        self.modalPresentationStyle = .formSheet
        if #available(iOS 16.0, *) {
            self.presentationController?.delegate = self
        }
    }

    @objc private func cancelSurvey() {
        if viewModel.shouldConfirmCancel {
            let alert = UIAlertController(
                title: viewModel.closeConfirmation.title,
                message: viewModel.closeConfirmation.message,
                preferredStyle: .actionSheet
            )

            alert.addAction(
                UIAlertAction(
                    title: viewModel.closeConfirmation.closeButtonTitle,
                    style: .destructive
                ) { _ in
                    self.cancel()
                })

            alert.addAction(
                UIAlertAction(
                    title: viewModel.closeConfirmation.continueButtonTitle,
                    style: .cancel
                ))

            alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            self.present(alert, animated: true)
        } else {
            cancel()
        }
    }

    private func cancel(partial: Bool = false) {
        viewModel.cancel(partial: partial)
        dismissViewController()
    }

    private func dismissViewController() {
        if let navigationController = self.navigationController {
            navigationController.dismiss(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    // MARK: - SurveyViewModelDelegate

    func surveyViewModelDidFinish(_ viewModel: SurveyViewModel) {
        guard viewModel.thankYouMessage != nil else {
            self.dismissViewController()
            return
        }

        // The task inherits this @MainActor context. `try?` keeps the closure non-throwing
        // (so the error from a cancelled sleep isn't silently dropped) and still dismisses
        // right away if the wait is cut short.
        Task {
            // Wait briefly to show the thank you message before dismissing.
            try? await Task.sleep(nanoseconds: 8 * (NSEC_PER_SEC / 10))
            self.dismissViewController()
        }
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {}

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {}

    func surveyViewModelPageWillChange(_ viewModel: SurveyViewModel) {
        view.endEditing(true)
    }

    func surveyViewModelPageDidChange(_ viewModel: SurveyViewModel) {
        // `SurveyView` slides only its question list (keyed by `pageTransitionID`), so the
        // bottom bar with the advance button and page indicator stays in place.
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.pageTransitionID += 1
        }
    }
}

extension SurveyHostingController: UIGestureRecognizerDelegate {
    /// Ignores taps on text inputs, so moving between fields doesn't make the keyboard flicker.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView {
                return false
            }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension SurveyHostingController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return !viewModel.shouldConfirmCancel
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        cancelSurvey()
    }
}
