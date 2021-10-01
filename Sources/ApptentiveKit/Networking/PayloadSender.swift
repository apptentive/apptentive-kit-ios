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
    let requestRetrier: HTTPRequestStarting

    /// The provider of credentials to use when connecting to the API.
    var credentialsProvider: APICredentialsProviding? {
        didSet {
            if let _ = self.credentialsProvider {
                self.sendPayloads()
            }
        }
    }

    /// The currently in-flight API request, if any.
    private var currentPayloadIdentifier: String? = nil

    /// The repository to use when loading/saving payloads from/to persistent storage.
    var repository: FileRepository<[Payload]>? {
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
    init(requestRetrier: HTTPRequestStarting) {
        self.requestRetrier = requestRetrier
        self.payloads = [Payload]()
    }

    /// Enqueues a payload for sending and triggers the queue to send the next available request.
    /// - Parameters:
    ///   - payload: The payload to send.
    ///   - persistEagerly: Whether the pay load should be saved to persistent storage ASAP.
    func send(_ payload: Payload, persistEagerly: Bool = false) {
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

    /// Tells the payload sender to finish sending any queued payloads, call the completion handler, and suspend itself.
    /// - Parameter completionHandler: A completion handler that is called once the payload queue is empty.
    func drain(completionHandler: @escaping () -> Void) {
        self.drainCompletionHandler = completionHandler
        self.isDraining = true
    }

    /// Resumes the payload sender.
    ///
    /// If the payload sender is draining, it cancels the drain operation, but the completion handler will still be called
    /// once the payload queue is empty.
    func resume() {
        self.isSuspended = false
        self.isDraining = false

        self.sendPayloads()
    }

    /// Helper method to build the payload sender's repository object.
    /// - Parameters:
    ///   - containerURL: The URL in which to find the file.
    ///   - filename: The name of the file.
    ///   - fileManager: The `FileManager` object to use for accessing the file.
    /// - Returns: The newly-created repository object.
    static func createRepository(containerURL: URL, filename: String, fileManager: FileManager) -> PropertyListRepository<[Payload]> {
        return PropertyListRepository<[Payload]>(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }

    /// Saves any unsaved payloads, for example when the app exits.
    func savePayloadsIfNeeded() throws {
        if let repository = self.repository, self.payloadsNeedSaving {
            try repository.save(self.payloads)
            self.payloadsNeedSaving = false
        }
    }

    /// The payloads waiting to be sent.
    private var payloads: [Payload] {
        didSet {
            if self.payloads != oldValue {
                self.payloadsNeedSaving = true
            }
        }
    }

    private var payloadsNeedSaving: Bool = false

    private var isSuspended: Bool = false

    private var isDraining: Bool = false

    private var drainCompletionHandler: (() -> Void)?

    /// Send any queued payloads to the API.
    private func sendPayloads() {
        guard !isSuspended else {
            ApptentiveLogger.network.debug("Payload sender is suspended")
            return
        }

        guard let credentials = self.credentialsProvider else {
            ApptentiveLogger.payload.debug("Payload sender not active.")
            return
        }

        guard currentPayloadIdentifier == nil else {
            ApptentiveLogger.network.debug("Already sending a payload")
            return
        }

        guard let firstPayload = self.payloads.first else {
            ApptentiveLogger.payload.debug("No payloads waiting to be sent.")

            //  Call the completion handler regardless of whether a call to `resume` may have reset the isDraining flag.
            self.drainCompletionHandler?()
            self.drainCompletionHandler = nil

            if self.isDraining {
                ApptentiveLogger.payload.debug("Drain: Finished sending queued payloads. Suspending.")

                self.isSuspended = true
                self.isDraining = false
            }

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

            case .failure(let error):
                ApptentiveLogger.payload.error("Permanent failure when sending \(firstPayload): \(error.localizedDescription). Removing from queue.")
            }

            self.payloads.removeFirst()

            self.currentPayloadIdentifier = nil

            self.sendPayloads()
        }
    }
}
