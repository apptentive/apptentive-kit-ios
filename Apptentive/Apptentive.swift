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
    func authenticate(key: String, signature: String, completion: @escaping (Bool)->())
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
    
    required init(requestor: HTTPRequesting) {
        self.requestor = requestor
    }
    
    func authenticate(key: String, signature: String, completion: @escaping (Bool) -> ()) {
        let request = Self.buildRequest(key: key, signature: signature, url: URL(string: "https://api.apptentive.com/conversations")!)
        
        requestor.sendRequest(request) { (data, response, error) in
            let success = Self.processResponse(response: response)
            
            completion(success)
        }
    }
    
    static func buildRequest(key: String, signature: String, url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(key, forHTTPHeaderField: "APPTENTIVE-KEY")
        request.addValue(signature, forHTTPHeaderField: "APPTENTIVE-SIGNATURE")
        
        return request
    }
    
    static func processResponse(response: URLResponse?) -> Bool {
        if let response = response as? HTTPURLResponse {
            let statusCode = response.statusCode
            
            return statusCode == 201
        }
        
        return false
    }
}

public class Apptentive {
    let authenticator: Authenticating
    
    init(authenticator: Authenticating) {
        self.authenticator = authenticator
    }
    
    public func register(key: String, signature: String, completion: @escaping (Bool)->()) {
        self.authenticator.authenticate(key: key, signature: signature, completion: completion)
    }
}
