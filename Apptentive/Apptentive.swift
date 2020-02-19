//
//  Apptentive.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Foundation

public protocol SessionWrapper {
	func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> ())
}


public class Apptentive {
	let sessionWrapper: SessionWrapper

	public init(sessionWrapper: SessionWrapper) {
		self.sessionWrapper = sessionWrapper
	}

	public func register(credentials: Credentials, completion: @escaping (Error?) -> ()) {
		var request = URLRequest(url: URL(string: "https://api.apptentive.com/conversations")!)
		request.addValue(credentials.key, forHTTPHeaderField: "APPTENTIVE-KEY")
		request.addValue(credentials.signature, forHTTPHeaderField: "APPTENTIVE-SIGNATURE")
		request.httpMethod = "POST"

		sessionWrapper.sendRequest(request) { (data, response, error) in
			if (response as! HTTPURLResponse).statusCode == 201 {
				completion(nil)
			}
		}
	}

	public struct Credentials {
		let key: String
		let signature: String

		public init(key: String, signature: String) {
			self.key = key
			self.signature = signature
		}
	}
}

public enum ApptentiveError: Error {
	
	case invalidCredentials
}
