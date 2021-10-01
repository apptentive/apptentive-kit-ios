//
//  HTTPRequestRetrier.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Used by payload sender in place of the class below for better testability.
protocol HTTPRequestStarting {
    func start<T: Decodable>(_ endpoint: HTTPEndpoint, identifier: String, completion: @escaping (Result<T, Error>) -> Void)
}

/// Retries HTTP requests until they either succeed or permanently fail.
class HTTPRequestRetrier: HTTPRequestStarting {
    /// The policy to use for retrying requests.
    private(set) var retryPolicy: HTTPRetryPolicy

    /// The HTTP client to use for requests.
    let client: HTTPClient

    /// The queue to use for calling completion handlers.
    let dispatchQueue: DispatchQueue

    /// The list of in-progress requests (either active, waiting for response, or waiting to retry).
    private var requests: [String: RequestWrapper]

    /// Creates a new request retrier.
    /// - Parameters:
    ///   - retryPolicy: The policy to use for retrying requests.
    ///   - client: The HTTP client to use for requests.
    ///   - queue: The queue to use for calling completion handlers.
    internal init(retryPolicy: HTTPRetryPolicy, client: HTTPClient, queue: DispatchQueue) {
        self.retryPolicy = retryPolicy
        self.client = client
        self.dispatchQueue = queue

        self.requests = [String: RequestWrapper]()
    }

    /// Starts a new request with the given parameters.
    /// - Parameters:
    ///   - endpoint: The HTTP endpoint of the request.
    ///   - identifier: A string that identifies the request.
    ///   - completion: A completion handler to call when the request either succeeds or fails permanently.
    func start<T: Decodable>(_ endpoint: HTTPEndpoint, identifier: String, completion: @escaping (Result<T, Error>) -> Void) {
        let wrapper = RequestWrapper(endpoint: endpoint)

        let request = self.client.request(endpoint) { (result: Result<T, Error>) in
            self.processResult(result, identifier: identifier, completion: completion)
        }

        wrapper.request = request
        self.requests[identifier] = wrapper
    }

    /// Starts a new request with the given parameters if another request with the same identifier is not already in progress.
    ///
    /// This is useful for instances where the same request might be triggered multiple times but only one request is desirable.
    /// The completion handler for a duplicate request will not be called.
    /// - Parameters:
    ///   - endpoint: The HTTP endpoint of the request.
    ///   - identifier: A string that identifies the request.
    ///   - completion: A completion handler to call when the request either succeeds or fails permanently.
    func startUnlessUnderway<T: Decodable>(_ endpoint: HTTPEndpoint, identifier: String, completion: @escaping (Result<T, Error>) -> Void) {
        if self.requests[identifier] != nil {
            ApptentiveLogger.network.info("A request with identifier \(identifier) is already underway. Skipping.")

            return
        }

        self.start(endpoint, identifier: identifier, completion: completion)
    }

    /// Processes the response created by the HTTP client to determine if the request should be retried.
    /// - Parameters:
    ///   - result: The result of the HTTP client's request.
    ///   - identifier: The identifier of the request that may be retried.
    ///   - completion: The completion handler supplied by the original caller for this retrying request, to be called when the request succeeds or fails permanently.
    private func processResult<T: Decodable>(_ result: Result<T, Error>, identifier: String, completion: @escaping (Result<T, Error>) -> Void) {
        switch result {
        case .success:
            self.retryPolicy.resetRetryDelay()
            self.requests[identifier] = nil

            self.dispatchQueue.async {
                completion(result)
            }

        case .failure(let error as HTTPClientError):
            if self.retryPolicy.shouldRetry(inCaseOf: error) {
                self.retryPolicy.incrementRetryDelay()
                let retryDelayMilliseconds = Int(self.retryPolicy.retryDelay) * 1000

                ApptentiveLogger.network.info("Retriable error sending API request with identifier ”\(identifier)”: \(error.localizedDescription). Retrying in \(retryDelayMilliseconds) ms.")

                self.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(retryDelayMilliseconds)) {
                    guard let wrapper = self.requests[identifier] else {
                        ApptentiveLogger.network.warning("Request with identifier \(identifier) cancelled or missing when attempting to retry.")
                        return
                    }

                    wrapper.request = self.client.request(
                        wrapper.endpoint,
                        completion: { (result: Result<T, Error>) in
                            self.processResult(result, identifier: identifier, completion: completion)
                        })
                }
            } else {
                ApptentiveLogger.network.info("Permanent failure when sending request with identifier “\(identifier)”: \(error.localizedDescription).")
                fallthrough
            }

        default:
            self.requests[identifier] = nil

            self.dispatchQueue.async {
                completion(result)
            }
        }
    }

    /// Describes a request's endpoint and in-flight HTTP request.
    class RequestWrapper {
        let endpoint: HTTPEndpoint
        var request: HTTPCancellable?

        internal init(endpoint: HTTPEndpoint, request: HTTPCancellable? = nil) {
            self.endpoint = endpoint
            self.request = request
        }
    }
}
