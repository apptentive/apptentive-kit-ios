//
//  Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// The main interface to the Apptentive SDK.
public class Apptentive {
    /// The shared instance of the Apptentive SDK.
    ///
    /// This property is populated lazily upon access. You can also manually create an instance of this class and pass it to the appropriate calls sites.
    public static let shared = Apptentive()

    let baseURL: URL
    var client: HTTPClient<ApptentiveV9API>?

    /// An object that overrides the `InteractionPresenter` class used to display interactions to the user.
    public var interactionPresenter: InteractionPresenter

    /// Creates a new instance of the Apptentive interface.
    ///
    /// Calling this method manually has no effect on the value of the `shared` static property.
    /// - Parameters:
    ///   - baseURL: The URL of the Apptentive server that the SDK will communicate with.
    ///   - interactionPresenter: An object that overrides the `InteractionPresenter` class used to display interactions  to the user.
    public init(baseURL: URL? = nil, interactionPresenter: InteractionPresenter? = nil) {
        // swift-format-ignore
        self.baseURL = baseURL ?? URL(string: "https://api.apptentive.com/")!
        self.interactionPresenter = interactionPresenter ?? InteractionPresenter()
    }

    /// Provides the SDK with the credentials necessary to connect to the Apptentive API.
    /// - Parameters:
    ///   - credentials: The `AppCredentials` object containing your Apptentive key and signature.
    ///   - completion: A completion handler that is called after the SDK succeeds or fails to connect to the Apptentive API.
    public func register(credentials: AppCredentials, completion: @escaping (Bool) -> Void) {
        self.client = HTTPClient<ApptentiveV9API>(requestor: URLSession.shared, baseURL: self.baseURL)

        var conversation = Conversation(environment: Environment())
        conversation.appCredentials = credentials

        self.client?.request(.createConversation(conversation)) { (result: (Result<ConversationResponse, Error>)) in
            switch result {
            case .success(_):
                completion(true)

            case .failure(_):
                completion(false)
            }
        }
    }

    /// Contains the credentials necessary to connect to the Apptentive API.
    public struct AppCredentials {
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
}

public enum ApptentiveError: Error {
    case invalidCustomDataType(Any?)
    case internalInconsistency
}
