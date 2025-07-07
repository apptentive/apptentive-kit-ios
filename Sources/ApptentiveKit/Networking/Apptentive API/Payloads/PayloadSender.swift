//
//  PayloadSender.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

protocol PayloadAuthenticationDelegate: AnyObject, Sendable {
    func authenticationDidFail(with errorResponse: ErrorResponse?)
}

protocol PayloadSending: Actor {
    func load(from loader: Loader) async throws
    func send(_ payload: Payload, persistEagerly: Bool) async
    func drain() async
    func resume() async
    func updateCredentials(_ credentials: PayloadStoredCredentials, for tag: String, encryptionContext: Payload.Context.EncryptionContext?) async throws
    func savePayloadsIfNeeded() async throws
    func setAuthenticationDelegate(_ authenticationDelegate: PayloadAuthenticationDelegate) async
    func makeSaver(containerURL: URL, filename: String)
    func destroySaver()
    func setAppCredentials(_ appCredentials: Apptentive.AppCredentials?) async
}

/// Sends fire-and-forget updates to the API.
actor PayloadSender: PayloadSending {
    static let errorKey = "error"
    static let payloadKey = "payload"

    /// The HTTP client to use to send payloads to the API.
    let requestRetrier: HTTPRequestStarting

    /// The notification center to use to post notifications.
    let notificationCenter: NotificationCenter

    /// The decoder to use when decoding the response.
    let jsonDecoder: JSONDecoder

    /// The encoder to use when transcoding the payload to update credentials.
    let jsonEncoder: JSONEncoder

    /// Creates a new payload sender.
    /// - Parameters:
    ///   - requestRetrier: The HTTPRequestRetrier instance to use to connect to the API.
    ///   - notificationCenter: The NotificationCenter object on which to post notifications about payload status.
    init(requestRetrier: HTTPRequestStarting, notificationCenter: NotificationCenter) {
        self.requestRetrier = requestRetrier
        self.notificationCenter = notificationCenter
        self.payloads = [Payload]()
        self.jsonDecoder = JSONDecoder.apptentive
        self.jsonEncoder = JSONEncoder.apptentive
    }

    func setAuthenticationDelegate(_ authenticationDelegate: any PayloadAuthenticationDelegate) async {
        self.authenticationDelegate = authenticationDelegate
    }

    func setAppCredentials(_ appCredentials: Apptentive.AppCredentials?) async {
        self.appCredentials = appCredentials
    }

    func load(from loader: Loader) async throws {
        self.enqueuePayloads(try loader.loadPayloads())
    }

    func makeSaver(containerURL: URL, filename: String) {
        self.setSaver(Self.createSaver(containerURL: containerURL, filename: filename, fileManager: FileManager()))
    }

    func setSaver(_ saver: Saver<[Payload]>) {
        self.saver = saver
    }

    func destroySaver() {
        self.saver = nil
    }

    /// Enqueues a payload for sending and triggers the queue to send the next available request.
    /// - Parameters:
    ///   - payload: The payload to send.
    ///   - persistEagerly: Whether the pay load should be saved to persistent storage ASAP.
    func send(_ payload: Payload, persistEagerly: Bool = false) async {
        guard payload.tag != "loggedOut" else {
            Logger.default.debug("Ignoring payload for logged-out conversation")
            return
        }

        Logger.payload.debug("Enqueuing new \(payload).")

        self.enqueuePayloads([payload])

        self.notificationCenter.post(name: Notification.Name.payloadEnqueued, object: self, userInfo: [Self.payloadKey: payload])

        if persistEagerly {
            do {
                try await self.savePayloadsIfNeeded()
            } catch let error {
                Logger.payload.error("Unable to save important payload: \(error).")
                apptentiveCriticalError("Unable to save important payload: \(error).")
            }
        }

        self.sendPayloads()
    }

    /// Tells the payload sender to finish sending any queued payloads and suspend itself.
    func drain() async {
        await withCheckedContinuation { continuation in
            self.isDraining = true
            self.drainContinuation = continuation
        }
    }

    private func setIsSuspended(_ isSuspended: Bool) {
        self.isSuspended = isSuspended
    }

    private func setIsDraining(_ isDraining: Bool) {
        self.isDraining = isDraining
    }

    /// Resumes the payload sender.
    ///
    /// If the payload sender is draining, it cancels the drain operation, but the completion handler will still be called
    /// once the payload queue is empty.
    func resume() async {
        self.setIsSuspended(false)
        self.setIsDraining(false)
        self.sendPayloads()
    }

    func updateCredentials(_ credentials: PayloadStoredCredentials, for tag: String, encryptionContext: Payload.Context.EncryptionContext?) async throws {
        for (index, payload) in self.payloads.enumerated() {
            if payload.tag == tag {
                try self.payloads[index].updateCredentials(credentials, using: self.jsonEncoder, decoder: self.jsonDecoder, encryptionContext: encryptionContext)
            }
        }

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
    func savePayloadsIfNeeded() async throws {
        if let saver = self.saver, self.payloadsNeedSaving {
            try saver.save(self.payloads)
            self.payloadsNeedSaving = false
        }
    }

    /// The saver to use when saving payloads to persistent storage.
    var saver: Saver<[Payload]>?

    /// The app credentials to use when sending payloads.
    var appCredentials: Apptentive.AppCredentials?

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

    /// A delegate object that supplies app credentials and is notified of authentication failures.
    private weak var authenticationDelegate: PayloadAuthenticationDelegate?

    /// A method that is called when the draining process completes.
    private var drainContinuation: CheckedContinuation<Void, Never>?

    /// The payloads waiting to be sent.
    private(set) var payloads: [Payload] {
        didSet {
            if self.payloads != oldValue {
                self.payloadsNeedSaving = true
            }
        }
    }

    /// Enqueue an array of payloads.
    /// - Parameter payloadsToPush: An array of payloads to add to the end of the payload queue.
    private func enqueuePayloads(_ payloadsToPush: [Payload]) {
        self.payloads = payloadsToPush + self.payloads
    }

    /// Send any queued payloads to the API.
    private func sendPayloads() {
        guard !isSuspended else {
            Logger.payload.debug("Payload sender is suspended")
            return
        }

        guard let appCredentials = self.appCredentials else {
            Logger.payload.debug("Payload sender not active.")
            return
        }

        guard currentPayloadIdentifier == nil else {
            Logger.payload.debug("Already sending a payload")
            return
        }

        guard let firstPayload = self.payloads.first(where: { $0.credentials.areValid }) else {
            Logger.payload.debug("No credentialed payloads waiting to be sent.")

            //  Call the completion handler regardless of whether a call to `resume` may have reset the isDraining flag.
            self.drainContinuation?.resume()
            self.drainContinuation = nil

            if self.isDraining {
                Logger.payload.debug("Drain: Finished sending queued payloads. Suspending.")

                self.isSuspended = true
                self.isDraining = false
            }

            return
        }

        let credentials = PayloadAPICredentials(appCredentials: appCredentials, payloadCredentials: firstPayload.credentials)

        Logger.payload.debug("Sending \(firstPayload).")

        let apiRequest = PayloadRequest(payload: firstPayload, credentials: credentials, decoder: self.jsonDecoder)

        self.currentPayloadIdentifier = firstPayload.identifier

        Task {
            do {
                let _: PayloadResponse = try await self.requestRetrier.start(apiRequest, identifier: firstPayload.identifier)
                Logger.payload.debug("Successfully sent \(firstPayload). Removing from queue.")
                self.notificationCenter.post(name: Notification.Name.payloadSent, object: self, userInfo: [Self.payloadKey: firstPayload])
                self.dequeuePayload(with: firstPayload.identifier)
            } catch HTTPClientError.unauthorized(_, let data) {
                self.clearCredentialsFromPayloads(with: firstPayload.tag)
                self.notifyDelegateOfAuthenticationFailure(data: data)
            } catch let error {
                Logger.payload.error("Permanent failure when sending \(firstPayload): \(error.localizedDescription). Removing from queue.")
                self.notificationCenter.post(name: Notification.Name.payloadFailed, object: self, userInfo: [Self.payloadKey: firstPayload, Self.errorKey: error])
                self.dequeuePayload(with: firstPayload.identifier)
            }

            self.currentPayloadIdentifier = nil

            self.sendPayloads()
        }

        self.notificationCenter.post(name: Notification.Name.payloadSending, object: self, userInfo: [Self.payloadKey: firstPayload])
    }

    private func notifyDelegateOfAuthenticationFailure(data: Data?) {
        if let data = data {
            do {
                let errorResponse = try self.jsonDecoder.decode(ErrorResponse.self, from: data)
                self.authenticationDelegate?.authenticationDidFail(with: errorResponse)
            } catch let error {
                Logger.payload.error("Unexpected authentication failure response data \(String(data: data, encoding: .utf8) ?? "<binary data>"), error: \(error).")
            }
        }
    }

    private func dequeuePayload(with identifier: String) {
        self.payloads.removeAll(where: { $0.identifier == identifier })
    }

    private func clearCredentialsFromPayloads(with tag: String) {
        for (index, payload) in self.payloads.enumerated() {
            if payload.tag == tag {
                payloads[index].clearCredentials()
            }
        }
    }
}

struct PayloadRequest: HTTPRequestBuilding {
    let payload: Payload
    let credentials: APICredentialsProviding
    let decoder: JSONDecoder

    init(payload: Payload, credentials: APICredentialsProviding, decoder: JSONDecoder) {
        self.payload = payload
        self.credentials = credentials
        self.decoder = decoder
    }

    var method: HTTPMethod {
        return self.payload.method
    }

    func headers(userAgent: String?, languageCode: String?) throws -> [String: String] {
        return ApptentiveAPI.buildHeaders(
            credentials: self.credentials, contentType: self.payload.contentType, accept: HTTPContentType.json, acceptCharset: "UTF-8", acceptLanguage: languageCode, userAgent: userAgent, apiVersion: ApptentiveAPI.apiVersion)
    }

    func url(relativeTo baseURL: URL) throws -> URL {
        var components = URLComponents()

        components.path = self.credentials.transformPath(self.payload.path)

        guard let url = components.url(relativeTo: baseURL) else {
            throw ApptentiveAPIError.invalidURLString(self.payload.path)
        }

        return url
    }

    func body() throws -> Data? {
        return payload.bodyData
    }

    func transformResponse<T>(_ response: HTTPResponse) throws -> T where T: Decodable {
        let responseObject: T = try {
            if response.data.count == 0 {
                // Empty data is not valid JSON, so we need to use a custom placeholder decoder.
                return try T(from: ApptentiveAPI.EmptyDecoder())
            } else {
                return try self.decoder.decode(T.self, from: response.data)
            }
        }()

        return responseObject
    }
}
