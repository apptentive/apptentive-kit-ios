//
//  ApptentiveAuthenticator.swift
//  Apptentive
//
//  Created by Apptentive on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol Authenticating {
    func authenticate(credentials: Apptentive.Credentials, completion: @escaping (Bool)->())
}

class ApptentiveAuthenticator: Authenticating {
    let requestor: HTTPRequesting
    let url: URL

    typealias HTTPHeaders = [String: String]

    required init(url: URL, requestor: HTTPRequesting) {
        self.requestor = requestor
        self.url = url
    }

    struct Headers {
        static let apptentiveKey = "apptentive-key"
        static let apptentiveSignature = "apptentive-signature"
    }

    func authenticate(credentials: Apptentive.Credentials, completion: @escaping (Bool) -> ()) {
        let headers = Self.buildHeaders(credentials: credentials)
        let request = Self.buildRequest(url: self.url, method: "POST", headers: headers)
        
        requestor.sendRequest(request) { (data, response, error) in
            let success = Self.processResponse(response: response)
            
            completion(success)
        }
    }

    static func buildHeaders(credentials: Apptentive.Credentials) -> HTTPHeaders {
        return [
            Headers.apptentiveKey: credentials.key,
            Headers.apptentiveSignature: credentials.signature
        ]
    }
    
    static func buildRequest(url: URL, method: String, headers: HTTPHeaders) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers

        return request
    }
    
    static func processResponse(response: URLResponse?) -> Bool {
        if let response = response as? HTTPURLResponse {
            let statusCode = response.statusCode
            
            if statusCode == 200 {
                return true
            }
        }
        
        return false
    }
}
