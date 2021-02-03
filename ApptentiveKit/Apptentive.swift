//
//  Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// The main interface to the Apptentive SDK.
public class Apptentive: EnvironmentDelegate, InteractionDelegate {
    /// The shared instance of the Apptentive SDK.
    ///
    /// This object is created lazily upon access.
    public static let shared = Apptentive()

    /// An object that overrides the `InteractionPresenter` class used to display interactions to the user.
    public var interactionPresenter: InteractionPresenter

    /// The theme to apply to Apptentive UI.
    ///
    /// This property must be set before calling `register(credentials:)`.
    public var theme: UITheme = .apptentive

    /// Indicates a theme that will be applied to Apptentive UI.
    public enum UITheme {
        /// Apptentive cross-platform look and feel.
        case apptentive

        /// iOS default look and feel.
        case none
    }

    /// Provides the SDK with the credentials necessary to connect to the Apptentive API.
    /// - Parameters:
    ///   - credentials: The `AppCredentials` object containing your Apptentive key and signature.
    ///   - completion: A completion handler that is called after the SDK succeeds or fails to connect to the Apptentive API.
    public func register(credentials: AppCredentials, completion: ((Bool) -> Void)? = nil) {
        if case .apptentive = self.theme {
            self.applyApptentiveTheme()
        }

        self.backendQueue.async {
            self.backend.connect(appCredentials: credentials) { result in
                switch result {
                case .success:
                    ApptentiveLogger.default.info("Apptentive SDK registered successfully.")
                    completion?(true)

                case .failure(let error):
                    ApptentiveLogger.default.error("Failed to register Apptentive SDK: \(error)")
                    completion?(false)
                }
            }
        }
    }

    /// Contains the credentials necessary to connect to the Apptentive API.
    public struct AppCredentials: Codable, Equatable {
        let key: String
        let signature: String

        /// Creates a new `AppCredentials` object.
        /// - Parameters:
        ///   - key: The Apptentive Key that should be used when connecting to the Apptentive API.
        ///   - signature: The Apptentive Signature that should be used when connecting to the Apptentive API.
        public init(key: String, signature: String) {
            self.key = key
            self.signature = signature
        }
    }

    /// Engages the specified event, using the view controller (if any) as the presenting view controller for any interactions.
    /// - Parameters:
    ///   - event: The event to engage.
    ///   - viewController: The view controller from which any interactions triggered by this (or future) event(s) should be presented.
    ///   - completion: A completion handler that is called with a boolean indicating whether or not an interaction was presented.
    public func engage(event: Event, from viewController: UIViewController? = nil, completion: ((Bool) -> Void)? = nil) {
        if let presentingViewController = viewController {
            self.interactionPresenter.presentingViewController = presentingViewController
        }

        self.backendQueue.async {
            self.backend.engage(event: event, completion: completion)
        }
    }

    /// Creates a new Apptentive SDK object using the specified URL to communicate with the Apptentive API.
    ///
    /// This should only be used for testing the SDK against a server other than the production Apptentive API server.
    /// - Parameter apiBaseURL: The URL to use to communicate with the Apptentive API.
    public convenience init(apiBaseURL: URL) {
        self.init(baseURL: apiBaseURL)
    }

    // MARK: - Internal

    init(baseURL: URL? = nil, containerDirectory: String? = nil, backendQueue: DispatchQueue? = nil, environment: Environment? = nil) {
        // swift-format-ignore
        self.baseURL = baseURL ?? URL(string: "https://api.apptentive.com/")!
        self.backendQueue = backendQueue ?? DispatchQueue(label: "Apptentive Backend")
        self.environment = environment ?? Environment()
        self.containerDirectory = containerDirectory ?? "com.apptentive.feedback"

        self.backend = Backend(queue: self.backendQueue, environment: self.environment, baseURL: self.baseURL)
        self.interactionPresenter = InteractionPresenter()

        self.environment.delegate = self
        if self.environment.isProtectedDataAvailable {
            self.protectedDataDidBecomeAvailable(self.environment)
        }

        // Typically we will be initialized too late to receive the ApplicationWillEnterForeground
        // notification, so we have to manually record a launch event here.
        if self.environment.isInForeground {
            self.engage(event: .launch())
        }

        self.backend.frontend = self
        self.interactionPresenter.delegate = self
    }

    // MARK: InteractionDelegate

    func send(surveyResponse: SurveyResponse) {
        self.backendQueue.async {
            self.backend.send(surveyResponse: surveyResponse)
        }
    }

    func engage(event: Event) {
        self.engage(event: event, from: nil)
    }

    func requestReview(completion: @escaping (Bool) -> Void) {
        self.environment.requestReview(completion: completion)
    }

    /// Asks the system to open the specified URL.
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - completion: Called with a value indicating whether the URL was successfully opened.
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        self.environment.open(url, completion: completion)
    }

    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        self.backendQueue.async {
            self.backend.invoke(invocations, completion: completion)
        }
    }

    // MARK: EnvironmentDelegate

    func protectedDataDidBecomeAvailable(_ environment: Environment) {
        self.backendQueue.async {
            do {
                let containerURL = try environment.applicationSupportURL().appendingPathComponent(self.containerDirectory)

                try self.backend.load(containerURL: containerURL, fileManager: environment.fileManager)
            } catch let error {
                assertionFailure("Unable to access container (\(self.containerDirectory)) in Application Support directory: \(error)")
            }
        }
    }

    func applicationWillEnterForeground(_ environment: Environment) {
        self.engage(event: .launch())
    }

    func applicationDidEnterBackground(_ environment: Environment) {
        self.engage(event: .exit())
    }

    func applicationWillTerminate(_ environment: Environment) {
        if environment.isInForeground {
            self.engage(event: .exit())
        }
    }

    // MARK: - Private

    private let baseURL: URL
    private let backendQueue: DispatchQueue
    private let backend: Backend
    private let environment: Environment
    private let containerDirectory: String
}

enum ApptentiveError: Error {
    case internalInconsistency
    case invalidCustomDataType(Any?)
    case fileExistsAtContainerDirectoryPath
    case mismatchedCredentials
}
