//
//  Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// The main interface to the Apptentive SDK.
public class Apptentive: EnvironmentDelegate {
    /// The shared instance of the Apptentive SDK.
    ///
    /// This object is created lazily upon access.
    public static let shared = Apptentive()

    /// An object that overrides the `InteractionPresenter` class used to display interactions to the user.
    public var interactionPresenter: InteractionPresenter

    /// Provides the SDK with the credentials necessary to connect to the Apptentive API.
    /// - Parameters:
    ///   - credentials: The `AppCredentials` object containing your Apptentive key and signature.
    ///   - completion: A completion handler that is called after the SDK succeeds or fails to connect to the Apptentive API.
    public func register(credentials: AppCredentials, completion: ((Bool) -> Void)? = nil) {
        self.backendQueue.async {
            self.backend.connect(appCredentials: credentials, baseURL: self.baseURL) { result in
                if case let .failure(error) = result {
                    print("Connection failed with error: \(error)")
                    completion?(false)
                } else {
                    completion?(true)
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

    // MARK: - Internal

    init(baseURL: URL? = nil, containerDirectory: String? = nil, backendQueue: DispatchQueue? = nil, environment: Environment? = nil) {
        // swift-format-ignore
        self.baseURL = baseURL ?? URL(string: "https://api.apptentive.com/")!
        self.backendQueue = backendQueue ?? DispatchQueue(label: "Apptentive Backend")
        self.environment = environment ?? Environment()
        self.containerDirectory = containerDirectory ?? "com.apptentive.feedback"

        self.backend = Backend(queue: self.backendQueue, environment: self.environment)
        self.interactionPresenter = InteractionPresenter()

        self.environment.delegate = self
        if self.environment.isProtectedDataAvailable {
            self.protectedDataDidBecomeAvailable(self.environment)
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
