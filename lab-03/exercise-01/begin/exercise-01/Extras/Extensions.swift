//
//  Extensions.swift
//  exercise-03
//
//  Created by Martin Walsh on 28/11/2018.
//  Copyright © 2018 Auth0. All rights reserved.
//

import Foundation

extension URLRequest {
    func log() {
        print("\(httpMethod ?? "") \(self)")
        if let httpBody = httpBody {
            print("Body: \n \(String(describing: String(data: httpBody, encoding: .utf8)))")
        }
        print("Headers: \n \(String(describing: allHTTPHeaderFields))")
    }
}
