//
//  PayloadSender.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Sends fire-and-forget updates to the API.
class PayloadSender {

    /// The HTTP client to use to send payloads to the API.
    let requestRetrier: HTTPRequestRetrier<ApptentiveV9API>

    /// The provider of credentials to use when connecting to the API.
    var credentials: APICredentialsProviding? {
        didSet {
            if let _ = self.credentials {
                self.sendPayloads()
            }
        }
    }

    /// The payloads waiting to be sent.
    var payloads: [Payload]

    /// The currently in-flight API request, if any.
    var currentlySendingPayload = false

    /// Creates a new payload sender.
    /// - Parameter requestRetrier: The HTTPRequestRetrier instance to use to connect to the API.
    init(requestRetrier: HTTPRequestRetrier<ApptentiveV9API>) {
        self.requestRetrier = requestRetrier
        self.payloads = [Payload]()
    }

    /// Enqueues a payload for sending and triggers the queue to send the next available request.
    /// - Parameters:
    ///   - payload: The payload to send.
    ///   - conversation: The conversation associated with the payload.
    func send(_ payload: Payload, for conversation: Conversation) {
        self.payloads.append(payload)

        self.sendPayloads()
    }

    /// Send any queued payloads to the API.
    func sendPayloads() {
        guard let credentials = self.credentials else {
            ApptentiveLogger.network.debug("Payload sender not active")
            return
        }

        guard !currentlySendingPayload else {
            ApptentiveLogger.network.debug("Already sending a payload")
            return
        }

        guard let firstPayload = self.payloads.first else {
            ApptentiveLogger.network.debug("No payloads waiting to be sent")
            return
        }

        let apiRequest = ApptentiveV9API(credentials: credentials, path: firstPayload.path, method: firstPayload.method, bodyObject: ApptentiveV9API.HTTPBodyEncodable(value: firstPayload))

        self.requestRetrier.start(apiRequest, identifier: UUID().uuidString) { (result: Result<PayloadResponse, Error>) in
            switch result {
            case .success:
                ApptentiveLogger.network.debug("Successfully sent payload")
                self.payloads.removeFirst()

            case .failure(let error):
                ApptentiveLogger.network.error("Error sending payload: \(error.localizedDescription)")
                self.payloads.removeFirst()
            }

            self.currentlySendingPayload = false

            self.sendPayloads()
        }
    }
}
