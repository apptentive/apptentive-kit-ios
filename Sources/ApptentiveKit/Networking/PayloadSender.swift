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
    var payloads: [Payload] {
        didSet {
            if self.payloads != oldValue {
                self.payloadsNeedSaving = true
            }
        }
    }

    var payloadsNeedSaving: Bool = false

    var isSuspended: Bool = false

    /// The currently in-flight API request, if any.
    var currentPayloadIdentifier: String? = nil

    var repository: PropertyListRepository<[Payload]>? {
        didSet {
            do {
                guard let repository = repository, repository.fileExists else {
                    ApptentiveLogger.default.debug("No payload queue in persistent storage. Starting from scratch.")
                    return
                }

                let savedPayloads = try repository.load()

                ApptentiveLogger.default.debug("Merging \(savedPayloads.count) saved payloads into in-memory queue.")
                self.payloads = savedPayloads + self.payloads
            } catch let error {
                ApptentiveLogger.default.error("Unable to load payload queue: \(error).")
                assertionFailure("Payload queue file exists but can't be read (error: \(error.localizedDescription)).")
            }
        }
    }

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
    ///   - persistEagerly: Whether the pay load should be saved to persistent storage ASAP.
    func send(_ payload: Payload, for conversation: Conversation, persistEagerly: Bool = false) {
        ApptentiveLogger.payload.debug("Enqueuing new \(payload).")

        self.payloads.append(payload)

        if persistEagerly {
            do {
                try self.savePayloadsIfNeeded()
            } catch let error {
                ApptentiveLogger.network.error("Unable to save important payload: \(error).")
                assertionFailure("Unable to save important payload: \(error).")
            }
        }

        self.sendPayloads()
    }

    /// Send any queued payloads to the API.
    func sendPayloads() {
        guard !isSuspended else {
            ApptentiveLogger.network.debug("Payload sender is suspended")
            return
        }

        guard let credentials = self.credentials else {
            ApptentiveLogger.payload.debug("Payload sender not active.")
            return
        }

        guard currentPayloadIdentifier == nil else {
            ApptentiveLogger.network.debug("Already sending a payload")
            return
        }

        guard let firstPayload = self.payloads.first else {
            ApptentiveLogger.payload.debug("No payloads waiting to be sent.")
            return
        }

        ApptentiveLogger.payload.debug("Sending \(firstPayload).")

        let apiRequest = ApptentiveV9API(credentials: credentials, path: firstPayload.path, method: firstPayload.method, bodyObject: ApptentiveV9API.HTTPBodyEncodable(value: firstPayload))

        let identifier = UUID().uuidString
        self.currentPayloadIdentifier = identifier

        self.requestRetrier.start(apiRequest, identifier: identifier) { (result: Result<PayloadResponse, Error>) in
            switch result {
            case .success:
                ApptentiveLogger.payload.debug("Successfully sent \(firstPayload). Removing from queue.")

                self.payloads.removeFirst()

            case .failure(let error):
                if let clientError = error as? HTTPClientError, clientError.indicatesCancellation {
                    ApptentiveLogger.payload.debug("Payload \(firstPayload) request cancelled. Not retrying, not removing from queue.")
                } else {
                    ApptentiveLogger.payload.error("Permanent failure when sending \(firstPayload): \(error.localizedDescription). Removing from queue.")

                    self.payloads.removeFirst()
                }
            }

            self.currentPayloadIdentifier = nil

            self.sendPayloads()
        }
    }

    func savePayloadsIfNeeded() throws {
        if let repository = self.repository, self.payloadsNeedSaving {
            try repository.save(self.payloads)
            self.payloadsNeedSaving = false
        }
    }

    func suspend() {
        self.isSuspended = true

        if let identifier = self.currentPayloadIdentifier {
            self.requestRetrier.cancel(identifier: identifier)
        }
    }

    func resume() {
        self.isSuspended = false
    }

    static func createRepository(containerURL: URL, filename: String, fileManager: FileManager) -> PropertyListRepository<[Payload]> {
        return PropertyListRepository<[Payload]>(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }
}
