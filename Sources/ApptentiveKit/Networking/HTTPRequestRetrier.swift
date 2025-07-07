//
//  HTTPRequestRetrier.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/18/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

protocol HTTPRequestStarting: Actor {
    func start<T>(_ builder: HTTPRequestBuilding, identifier: String) async throws -> T where T: Decodable
}

actor HTTPRequestRetrier: HTTPRequestStarting {
    func setClient(_ client: HTTPClient) {
        self.client = client
    }

    func resetRetryDelay() {
        self.retryDelay.resetRetryDelay()
    }

    /// The HTTP client to use for requests.
    private var client: HTTPClient?

    /// The list of in-progress requests (either active, waiting for response, or waiting to retry).
    private var tasks = [String: Task<Decodable & Sendable, Error>]()

    private var retryDelay = RetryDelay()

    func start<T>(_ builder: HTTPRequestBuilding, identifier: String) async throws -> T where T: Decodable & Sendable {
        defer {
            self.tasks[identifier] = nil
        }

        guard let client = self.client else {
            throw ApptentiveError.internalInconsistency
        }

        let task = Task<Decodable & Sendable, Error> {
            while true {
                do {
                    let response = try await client.request(builder)
                    let object: T = try builder.transformResponse(response)
                    self.retryDelay.resetRetryDelay()

                    return object
                } catch HTTPClientError.unauthorized(let response, let data) {
                    // Don't retry requests with auth failure.
                    throw HTTPClientError.unauthorized(response, data)
                } catch HTTPClientError.clientError(let response, let data) {
                    // Don't retry other 4xx requests here.
                    throw HTTPClientError.clientError(response, data)
                } catch HTTPClientError.connectionError(let connectionError) {
                    // Retry connection errors
                    Logger.network.info("Retriable connection error sending API request with identifier ”\(identifier)”: \(connectionError.localizedDescription).")
                } catch HTTPClientError.serverError(let response, let data) {
                    let responseString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no text response>"
                    Logger.network.info("Retriable server error sending API request with identifier ”\(identifier)”: \(response.statusCode) \(responseString).")
                } catch let error {
                    throw error
                }

                self.retryDelay.incrementRetryDelay()
                try await Task.sleep(nanoseconds: self.retryDelay.retryDelayNanoseconds)
            }
        }

        self.tasks[identifier] = task

        // swift-format-ignore
        return try await task.value as! T
    }

    func requestIsUnderway(for identifier: String) -> Bool {
        return self.tasks[identifier] != nil
    }

    /// Cancels the request with the specified identifier.
    /// - Parameter identifier: The identifier for the request.
    func cancel(identifier: String) {
        if let task = self.tasks[identifier] {
            task.cancel()
        }
    }

    struct RetryDelay {
        let initialDelay: Double
        let multiplier: Double
        let useJitter: Bool

        private var baseRetryDelay: TimeInterval

        internal init(initialDelay: Double = 5.0, multiplier: Double = 2.0, useJitter: Bool = true) {
            self.initialDelay = initialDelay
            self.multiplier = multiplier
            self.useJitter = useJitter

            self.baseRetryDelay = initialDelay
        }

        var retryDelay: TimeInterval {
            let jitter = self.useJitter ? Double.random(in: 0..<1) : 1
            return self.baseRetryDelay * jitter
        }

        var retryDelayNanoseconds: UInt64 {
            return UInt64(retryDelay) * NSEC_PER_SEC
        }

        mutating func incrementRetryDelay() {
            self.baseRetryDelay *= multiplier
        }

        mutating func resetRetryDelay() {
            self.baseRetryDelay = self.initialDelay
        }
    }
}
