//
//  Apptentive.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Foundation

public typealias URLResult = (Data?, URLResponse?, Error?)

protocol Authenticating {
	func authenticate(credentials: Apptentive.Credentials, completion: @escaping (Bool)->())
}

protocol HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (URLResult) -> ())
}

extension URLSession: HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (URLResult) -> ()) {
        let task = self.dataTask(with: request) { (data, response, error) in
            completion((data, response, error))
        }
        
        task.resume()
    }
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

public class Apptentive {
    let authenticator: Authenticating
    
    convenience init() {
        
        let url = URL(string: "https://api.apptentive.com/conversations")!
        let authenticator = ApptentiveAuthenticator(url: url, requestor: URLSession.shared)
        self.init(authenticator: authenticator)
    }
    
    init(authenticator: Authenticating) {
        self.authenticator = authenticator
    }
    
	public func register(credentials: Credentials, completion: @escaping (Bool)->()) {
		self.authenticator.authenticate(credentials: credentials, completion: completion)
    }

	public struct Credentials {
		let key: String
		let signature: String
	}
}
