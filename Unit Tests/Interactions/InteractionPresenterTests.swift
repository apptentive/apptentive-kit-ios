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

    func testPresentEnjoymentDialog() throws {
        try self.presentInteraction(try InteractionTestHelpers.loadInteraction(named: "EnjoymentDialog"))
    }

    func testPresentSurvey() throws {
        try self.presentInteraction(try InteractionTestHelpers.loadInteraction(named: "Survey"))
    }

    func testPresentTextModal() throws {
        try self.presentInteraction(try InteractionTestHelpers.loadInteraction(named: "TextModal"))
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

        XCTAssertThrowsError(try self.presentInteraction(fakeInteraction))
    }

    class FakeInteractionPresenter: InteractionPresenter {
        var viewModel: AnyObject?

        override func presentSurvey(with viewModel: SurveyViewModel) throws {
            self.viewModel = viewModel

            let fakeSurveyViewController = UIViewController()
            fakeSurveyViewController.view.tag = 333

            try self.presentViewController(fakeSurveyViewController)
        }

        override func presentEnjoymentDialog(with viewModel: EnjoymentDialogViewModel) throws {
            self.viewModel = viewModel

            let fakeAlertController = UIViewController()
            fakeAlertController.view.tag = 333

            try self.presentViewController(fakeAlertController)
        }

        override func presentTextModal(with viewModel: TextModalViewModel) throws {
            self.viewModel = viewModel

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

    private func presentInteraction(_ interaction: Interaction) throws {
        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        XCTAssertThrowsError(try interactionPresenter.presentInteraction(interaction, from: nil))

        let viewController = FakePresentingViewController()
        try interactionPresenter.presentInteraction(interaction, from: viewController)

        XCTAssertNotNil(interactionPresenter.viewModel)
        XCTAssertEqual(viewController, interactionPresenter.presentingViewController)
        XCTAssertEqual(viewController.fakePresentedViewController?.view.tag, 333)
    }
}
