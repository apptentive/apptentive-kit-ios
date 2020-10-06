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
        guard let surveyURL = Bundle(for: type(of: self)).url(forResource: "Survey - 3.1", withExtension: "json"), let surveyData = try? Data(contentsOf: surveyURL) else {
            return XCTFail("Unable to load test survey data")
        }

        guard let surveyInteraction = try? JSONDecoder().decode(Interaction.self, from: surveyData) else {
            return XCTFail("Unable to decode test survey data")
        }

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        XCTAssertThrowsError(try interactionPresenter.presentInteraction(surveyInteraction, from: nil))

        let viewController = FakePresentingViewController()
        try interactionPresenter.presentInteraction(surveyInteraction, from: viewController)

        XCTAssertNotNil(interactionPresenter.surveyViewModel)
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

        guard let fakeInteraction = try? JSONDecoder().decode(Interaction.self, from: fakeInteractionData) else {
            return XCTFail("Unable to decode test fake interaction data")
        }

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        XCTAssertThrowsError(try interactionPresenter.presentInteraction(fakeInteraction, from: nil))
    }

    class FakeInteractionPresenter: InteractionPresenter {
        var surveyViewModel: SurveyViewModel?

        override func presentSurvey(with viewModel: SurveyViewModel) throws {
            self.surveyViewModel = viewModel

            let fakeSurveyViewController = UIViewController()
            fakeSurveyViewController.view.tag = 333

            try self.presentViewController(fakeSurveyViewController)
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
