//
//  Apptentive.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Foundation

protocol Authenticating {
    func authenticate(key: String, signature: String, completion: @escaping (Bool)->())
}

protocol HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> ())
}

extension URLSession: HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        let task = self.dataTask(with: request, completionHandler: completion)
        
        task.resume()
    }
}

class ApptentiveAuthenticator: Authenticating {
    let requestor: HTTPRequesting
    
    required init(requestor: HTTPRequesting) {
        self.requestor = requestor
    }
    
    func authenticate(key: String, signature: String, completion: @escaping (Bool) -> ()) {
        
        // build request
        let url = URL(string: "https://api.apptentive.com/conversations")!
        var request = URLRequest(url: url)
        request.addValue(key, forHTTPHeaderField: "APPTENTIVE-KEY")
        request.addValue(signature, forHTTPHeaderField: "APPTENTIVE-SIGNATURE")
        request.httpMethod = "POST"
        
        // make request
        requestor.sendRequest(request) { (data, response, error) in
            
            // map response
            if let response = response as? HTTPURLResponse {
                let statusCode = response.statusCode
                
                let success = statusCode == 201
                completion(success)
            }
        }
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
