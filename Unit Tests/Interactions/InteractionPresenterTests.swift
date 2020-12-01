//
//  InteractionPresenterTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/4/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class InteractionPresenterTests: XCTestCase {
    var interactionPresenter: InteractionPresenter?

    override func setUp() {
        self.interactionPresenter = FakeInteractionPresenter()
        self.interactionPresenter?.sender = SpySender()
    }

    func testPresentSurvey() throws {
        guard let url = Bundle(for: type(of: self)).url(forResource: "Survey", withExtension: "json", subdirectory: "Test Interactions") else {
            return XCTFail("Unable to load test survey data")
        }

        let data = try Data(contentsOf: url)
        let interaction = try JSONDecoder().decode(Interaction.self, from: data)

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        XCTAssertThrowsError(try interactionPresenter.presentInteraction(interaction, from: nil))

        let viewController = FakePresentingViewController()
        try interactionPresenter.presentInteraction(interaction, from: viewController)

        XCTAssertNotNil(interactionPresenter.surveyViewModel)
        XCTAssertEqual(viewController, interactionPresenter.presentingViewController)
        XCTAssertEqual(viewController.fakePresentedViewController?.view.tag, 333)
    }

    func testPresentEnjoymentDialog() throws {
        guard let url = Bundle(for: type(of: self)).url(forResource: "EnjoymentDialog", withExtension: "json", subdirectory: "Test Interactions") else {
            return XCTFail("Unable to load test survey data")
        }

        let data = try Data(contentsOf: url)
        let interaction = try JSONDecoder().decode(Interaction.self, from: data)

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        XCTAssertThrowsError(try interactionPresenter.presentInteraction(interaction, from: nil))

        let viewController = FakePresentingViewController()
        try interactionPresenter.presentInteraction(interaction, from: viewController)

        XCTAssertNotNil(interactionPresenter.alertViewModel)
        XCTAssertEqual(viewController, interactionPresenter.presentingViewController)
        XCTAssertEqual(viewController.fakePresentedViewController?.view.tag, 333)
    }

    func testPresentUnimplemented() throws {
        let fakeInteractionString = """
                    {
                    "id": "abc123",
                    "type": "FakeInteraction",
                    }
            """
        guard let fakeInteractionData = fakeInteractionString.data(using: .utf8) else {
            return XCTFail("Unable to encode test fake interaction string")
        }

        let fakeInteraction = try JSONDecoder().decode(Interaction.self, from: fakeInteractionData)

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        XCTAssertThrowsError(try interactionPresenter.presentInteraction(fakeInteraction, from: nil))
    }

    class FakeInteractionPresenter: InteractionPresenter {
        var surveyViewModel: SurveyViewModel?
        var alertViewModel: AlertViewModel?

        override func presentSurvey(with viewModel: SurveyViewModel) throws {
            self.surveyViewModel = viewModel

            let fakeSurveyViewController = UIViewController()
            fakeSurveyViewController.view.tag = 333

            try self.presentViewController(fakeSurveyViewController)
        }

        override func presentEnjoymentDialog(with viewModel: EnjoymentDialogViewModel) throws {
            self.alertViewModel = viewModel

            let fakeAlertController = UIViewController()
            fakeAlertController.view.tag = 333

            try self.presentViewController(fakeAlertController)
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
        }

        override var isViewLoaded: Bool {
            return true
        }
    }

    class FakeView: UIView {
        override var window: UIWindow {
            return UIWindow()
        }
    }
}
