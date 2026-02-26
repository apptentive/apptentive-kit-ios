//
//  InteractionPresenterTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

struct InteractionPresenterTests {
    var interactionPresenter: InteractionPresenter?

    @MainActor init() {
        self.interactionPresenter = FakeInteractionPresenter()
        self.interactionPresenter?.delegate = SpyInteractionDelegate()
    }

    @Test func testShowAppleRatingDialog() async throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "AppleRatingDialog")

        try await self.interactionPresenter?.presentInteraction(interaction)
    }

    @Test func testPresentEnjoymentDialog() async throws {
        try await self.presentInteraction(InteractionTestHelpers.loadInteraction(named: "EnjoymentDialog"))
    }

    @Test func testPresentSurvey() async throws {
        try await self.presentInteraction(InteractionTestHelpers.loadInteraction(named: "Survey"))
    }

    @Test func testPresentTextModal() async throws {
        try await self.presentInteraction(InteractionTestHelpers.loadInteraction(named: "TextModal"))
    }

    @Test func testPresentUnimplemented() async throws {
        let fakeInteractionString = """
                    {
                    "id": "abc123",
                    "type": "FakeInteraction",
                    }
            """

        guard let fakeInteractionData = fakeInteractionString.data(using: .utf8) else {
            throw TestError(reason: "Unable to encode test fake interaction string")
        }

        let fakeInteraction = try JSONDecoder.apptentive.decode(Interaction.self, from: fakeInteractionData)

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            throw TestError(reason: "interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        await #expect(throws: InteractionPresenterError.self) {
            try await interactionPresenter.presentInteraction(fakeInteraction, from: nil)
        }
    }

    @Test func testDismssPresentedInteraction() async throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")
        let presentingViewController = await FakePresentingViewController()

        try await self.interactionPresenter?.presentInteraction(interaction, from: presentingViewController)

        let presentedViewController = try await #require(presentingViewController.fakePresentedViewController as? FakePresentedViewController)

        await self.interactionPresenter?.dismissPresentedViewController(animated: true)

        let didDismiss = await presentedViewController.didDismiss
        #expect(didDismiss)

        let spyInteractionDelegate = await self.interactionPresenter?.delegate as! SpyInteractionDelegate
        await #expect(spyInteractionDelegate.engagedEvent?.codePointName == "com.apptentive#TextModal#cancel")
        await #expect(spyInteractionDelegate.engagedEvent?.userInfo == EventUserInfo.dismissCause(.init(cause: "notification")))
    }

    @Test func testNoPresentingViewController() async throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")

        let interactionPresenter = try #require(self.interactionPresenter as? FakeInteractionPresenter)

        await #expect(throws: InteractionPresenterError.noPresentingViewController) {
            try await interactionPresenter.presentInteraction(interaction, from: nil)
        }
    }

    @MainActor class FakeInteractionPresenter: InteractionPresenter {
        var viewModel: AnyObject?

        override func presentSurvey(with surveyViewModel: SurveyViewModel) async throws {

            self.viewModel = surveyViewModel

            let fakeSurveyViewController = FakePresentedViewController()
            fakeSurveyViewController.view.tag = 333

            try await self.presentViewController(fakeSurveyViewController)
        }

        override func presentEnjoymentDialog(with viewModel: DialogViewModel) async throws {
            self.viewModel = viewModel

            let fakeAlertController = FakePresentedViewController()
            fakeAlertController.view.tag = 333

            try await self.presentViewController(fakeAlertController)
        }

        override func presentTextModal(with viewModel: DialogViewModel) async throws {
            self.viewModel = viewModel

            let fakeAlertController = FakePresentedViewController()
            fakeAlertController.view.tag = 333

            try await self.presentViewController(fakeAlertController)
        }
    }

    class FakePresentingViewController: UIViewController {
        var fakePresentedViewController: UIViewController?

        init() {
            super.init(nibName: nil, bundle: nil)
            self.view = FakeView()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
            self.fakePresentedViewController = viewControllerToPresent
            Task {
                completion?()
            }
        }

        override var isViewLoaded: Bool {
            return true
        }
    }

    class FakePresentedViewController: UIViewController {
        var didDismiss: Bool = false

        override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
            self.didDismiss = true
        }
    }

    class FakeView: UIView {
        override var window: UIWindow {
            return UIWindow()
        }
    }

    @MainActor private func presentInteraction(_ interaction: Interaction) async throws {
        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            throw NSError(domain: "interactionPresenter is nil or not a FakeInteractionPresenter", code: 123)
        }

        let viewController = FakePresentingViewController()

        try await interactionPresenter.presentInteraction(interaction, from: viewController)

        await MainActor.run {
            #expect(interactionPresenter.viewModel != nil)
            #expect(viewController == interactionPresenter.presentingViewController)
            #expect(viewController.fakePresentedViewController?.view.tag == 333)
        }
    }
}
