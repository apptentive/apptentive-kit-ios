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
    static let errorKey = "error"
    static let payloadKey = "payload"

    /// The HTTP client to use to send payloads to the API.
    let requestRetrier: HTTPRequestStarting

    /// The notification center to use to post notifications.
    let notificationCenter: NotificationCenter

    /// The provider of credentials to use when connecting to the API.
    var credentialsProvider: APICredentialsProviding? {
        didSet {
            if let _ = self.credentialsProvider {
                self.sendPayloads()
            }
        }
    }

    var attachmentManger: AttachmentManager?

    /// Creates a new payload sender.
    /// - Parameters:
    ///   - requestRetrier: The HTTPRequestRetrier instance to use to connect to the API.
    ///   - notificationCenter: The NotificationCenter object on which to post notifications about payload status.
    init(requestRetrier: HTTPRequestStarting, notificationCenter: NotificationCenter) {
        self.requestRetrier = requestRetrier
        self.notificationCenter = notificationCenter
        self.payloads = [Payload]()
    }

    func load(from loader: Loader) throws {
        self.payloads = try loader.loadPayloads() + self.payloads
    }

    /// Enqueues a payload for sending and triggers the queue to send the next available request.
    /// - Parameters:
    ///   - payload: The payload to send.
    ///   - persistEagerly: Whether the pay load should be saved to persistent storage ASAP.
    func send(_ payload: Payload, persistEagerly: Bool = false) {
        ApptentiveLogger.payload.debug("Enqueuing new \(payload).")

        self.payloads.append(payload)

        self.notificationCenter.post(name: Notification.Name.payloadEnqueued, object: self, userInfo: [Self.payloadKey: payload])

        if persistEagerly {
            do {
                try self.savePayloadsIfNeeded()
            } catch let error {
                ApptentiveLogger.payload.error("Unable to save important payload: \(error).")
                apptentiveCriticalError("Unable to save important payload: \(error).")
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

    /// Helper method to build the payload sender's saver object.
    /// - Parameters:
    ///   - containerURL: The URL in which to find the file.
    ///   - filename: The name of the file.
    ///   - fileManager: The `FileManager` object to use for accessing the file.
    /// - Returns: The newly-created saver object.
    static func createSaver(containerURL: URL, filename: String, fileManager: FileManager) -> PropertyListSaver<[Payload]> {
        return PropertyListSaver<[Payload]>(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }

    /// Saves any unsaved payloads, for example when the app exits.
    func savePayloadsIfNeeded() throws {
        if let saver = self.saver, self.payloadsNeedSaving {
            try saver.save(self.payloads)
            self.payloadsNeedSaving = false
        }
    }

    /// The saver to use when saving payloads to persistent storage.
    var saver: Saver<[Payload]>?

    /// The currently in-flight API request, if any.
    private var currentPayloadIdentifier: String? = nil

    /// Whether payloads from last session need to be loaded.
    private var payloadsNeedLoading: Bool = true

    /// Whether the in-memory payload queue should be saved to the saver.
    private var payloadsNeedSaving: Bool = false

    /// Whether the payload sender is suspended (paused).
    private var isSuspended: Bool = false

    /// Whether the payload sender is finishing sending payloads in the queue and then suspend.
    private var isDraining: Bool = false

    /// A method that is called when the draining process completes.
    private var drainCompletionHandler: (() -> Void)?

    /// The payloads waiting to be sent.
    private(set) var payloads: [Payload] {
        didSet {
            if self.payloads != oldValue {
                self.payloadsNeedSaving = true
            }
        }
    }

    /// Send any queued payloads to the API.
    private func sendPayloads() {
        guard !isSuspended else {
            ApptentiveLogger.payload.debug("Payload sender is suspended")
            return
        }

        guard let credentials = self.credentialsProvider else {
            ApptentiveLogger.payload.debug("Payload sender not active.")
            return
        }

        guard currentPayloadIdentifier == nil else {
            ApptentiveLogger.payload.debug("Already sending a payload")
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

        let apiRequest = ApptentiveV9API(credentials: credentials, path: firstPayload.path, method: firstPayload.method, bodyParts: firstPayload.bodyParts)

        let identifier = UUID().uuidString
        self.currentPayloadIdentifier = identifier

        self.requestRetrier.start(apiRequest, identifier: identifier) { (result: Result<PayloadResponse, Error>) in
            switch result {
            case .success:
                ApptentiveLogger.payload.debug("Successfully sent \(firstPayload). Removing from queue.")
                self.notificationCenter.post(name: Notification.Name.payloadSent, object: self, userInfo: [Self.payloadKey: firstPayload])

            case .failure(let error):
                ApptentiveLogger.payload.error("Permanent failure when sending \(firstPayload): \(error.localizedDescription). Removing from queue.")
                self.notificationCenter.post(name: Notification.Name.payloadFailed, object: self, userInfo: [Self.payloadKey: firstPayload, Self.errorKey: error])
            }

            self.payloads.removeFirst()

            self.currentPayloadIdentifier = nil

            self.sendPayloads()
        }

        self.notificationCenter.post(name: Notification.Name.payloadSending, object: self, userInfo: [Self.payloadKey: firstPayload])
    }
}
