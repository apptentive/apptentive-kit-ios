//
//  HTTPRequesting.swift
//  Apptentive
//
//  Created by Apptentive on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation


public typealias URLResult = (Data?, URLResponse?, Error?)

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
