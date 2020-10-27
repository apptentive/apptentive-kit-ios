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

    /// The dispatch queue to use to process API responses.
    let queue: DispatchQueue

    /// The HTTP client to use to send payloads to the API.
    let client: HTTPClient<ApptentiveV9API>

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
    var currentPayloadTask: HTTPCancellable?

    /// Creates a new payload sender.
    /// - Parameters:
    ///   - queue: The dispatch queue to use to process API responses.
    ///   - client: The HTTPClient instance to use to connect to the API.
    init(queue: DispatchQueue, client: HTTPClient<ApptentiveV9API>) {
        self.queue = queue
        self.client = client
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
            print("Payload sender not active")
            return
        }

        guard currentPayloadTask == nil else {
            print("Already sending a payload")
            return
        }

        guard let firstPayload = self.payloads.first else {
            print("No payloads waiting to be sent")
            return
        }

        let apiRequest = ApptentiveV9API(credentials: credentials, path: firstPayload.path, method: firstPayload.method, bodyObject: ApptentiveV9API.HTTPBodyEncodable(value: firstPayload))

        self.currentPayloadTask = client.request(apiRequest) { (result: Result<PayloadResponse, Error>) in
            self.queue.async {
                switch result {
                case .success:
                    print("Successfully sent payload")
                    self.payloads.removeFirst()

                case .failure(let error):
                    print("Error sending payload: \(error.localizedDescription)")
                    // Either here or somewhere in the HTTP client, it should retry the request if the error isn't a client error.
                    // For now, we'll just discard the payload.
                    self.payloads.removeFirst()
                }

                self.currentPayloadTask = nil

                self.sendPayloads()
            }
        }
    }
}
