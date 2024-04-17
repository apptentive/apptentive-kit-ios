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
        self.interactionPresenter?.delegate = SpyInteractionDelegate()
    }

    func testShowAppleRatingDialog() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "AppleRatingDialog")

        let expectation = self.expectation(description: "Interaction presented")

        self.interactionPresenter?.presentInteraction(interaction) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 10)
    }

    func testPresentEnjoymentDialog() throws {
        let expectation = self.expectation(description: "Interaction presented")

        self.presentInteraction(try InteractionTestHelpers.loadInteraction(named: "EnjoymentDialog")) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 10)
    }

    func testPresentSurvey() throws {
        let expectation = self.expectation(description: "Interaction presented")

        self.presentInteraction(try InteractionTestHelpers.loadInteraction(named: "Survey")) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 10)
    }

    func testPresentTextModal() throws {
        let expectation = self.expectation(description: "Interaction presented")

        self.presentInteraction(try InteractionTestHelpers.loadInteraction(named: "TextModal")) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 10)
    }

    func testPresentUnimplemented() throws {
        let expectation = self.expectation(description: "Interaction presented")

        let fakeInteractionString = """
                    {
                    "id": "abc123",
                    "type": "FakeInteraction",
                    }
            """

        guard let fakeInteractionData = fakeInteractionString.data(using: .utf8) else {
            return XCTFail("Unable to encode test fake interaction string")
        }

        let fakeInteraction = try JSONDecoder.apptentive.decode(Interaction.self, from: fakeInteractionData)

        self.presentInteraction(fakeInteraction) { result in
            if case .success = result {
                XCTFail("Should have an unimplemented error.")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 10)
    }

    func testDismssPresentedInteraction() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")
        let presentingViewController = FakePresentingViewController()

        let expectation = self.expectation(description: "Interaction presented")

        self.interactionPresenter?.presentInteraction(interaction, from: presentingViewController) { result in
            if case .failure(let error) = result {
                XCTFail(error.localizedDescription)
            }

            DispatchQueue.main.async {
                guard let presentedViewController = presentingViewController.fakePresentedViewController as? FakePresentedViewController else {
                    return XCTFail("No presented view controller, or is not fake presented view controller.")
                }

                self.interactionPresenter?.dismissPresentedViewController(animated: true)

                XCTAssertTrue(presentedViewController.didDismiss)

                let spyInteractionDelegate = self.interactionPresenter?.delegate as! SpyInteractionDelegate
                XCTAssertEqual(spyInteractionDelegate.engagedEvent?.codePointName, "com.apptentive#TextModal#cancel")
                XCTAssertEqual(spyInteractionDelegate.engagedEvent?.userInfo, EventUserInfo.dismissCause(.init(cause: "notification")))

                expectation.fulfill()
            }
        }

        self.wait(for: [expectation], timeout: 10)
    }

    func testNoPresentingViewController() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "TextModal")

        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return XCTFail("interactionPresenter is nil or not a FakeInteractionPresenter")
        }

        let expectation = self.expectation(description: "Interaction not presented")

        interactionPresenter.presentInteraction(interaction, from: nil) { result in
            if case .success = result {
                XCTFail()
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 10)
    }

    class FakeInteractionPresenter: InteractionPresenter {
        var viewModel: AnyObject?

        override func presentSurvey(with surveyViewModel: SurveyViewModel) throws {

            self.viewModel = surveyViewModel

            let fakeSurveyViewController = FakePresentedViewController()
            fakeSurveyViewController.view.tag = 333

            try self.presentViewController(fakeSurveyViewController)
        }

        override func presentEnjoymentDialog(with viewModel: DialogViewModel) throws {
            self.viewModel = viewModel

            let fakeAlertController = FakePresentedViewController()
            fakeAlertController.view.tag = 333

            try self.presentViewController(fakeAlertController)
        }

        override func presentTextModal(with viewModel: DialogViewModel, completion: @escaping (Result<Void, Error>) -> Void) {
            self.viewModel = viewModel

            let fakeAlertController = FakePresentedViewController()
            fakeAlertController.view.tag = 333

            do {
                try self.presentViewController(fakeAlertController)

                completion(.success(()))
            } catch let error {
                completion(.failure(error))
            }
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

    private func presentInteraction(_ interaction: Interaction, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let interactionPresenter = self.interactionPresenter as? FakeInteractionPresenter else {
            return completion(.failure(NSError(domain: "interactionPresenter is nil or not a FakeInteractionPresenter", code: 123)))
        }

        let viewController = FakePresentingViewController()

        interactionPresenter.presentInteraction(interaction, from: viewController) { result in
            if case .failure(let error) = result {
                return completion(.failure(error))
            }

            XCTAssertNotNil(interactionPresenter.viewModel)
            XCTAssertEqual(viewController, interactionPresenter.presentingViewController)
            XCTAssertEqual(viewController.fakePresentedViewController?.view.tag, 333)

            completion(.success(()))
        }
    }
}
