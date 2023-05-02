//
//  Utils.swift
//  exercise-01
//
//  Created by Martin Walsh on 10/12/2018.
//  Copyright © 2018 Auth0. All rights reserved.
//

import Foundation
import JWTDecode

func plistValues(bundle: Bundle) -> (clientId: String, domain: String)? {
    guard
        let path = bundle.path(forResource: "Auth0", ofType: "plist"),
        let values = NSDictionary(contentsOfFile: path) as? [String: Any]
        else {
            print("Missing Auth0.plist file with 'ClientId' and 'Domain' entries in main bundle!")
            return nil
    }
    
    guard
        let clientId = values["ClientId"] as? String,
        let domain = values["Domain"] as? String
        else {
            print("Auth0.plist file at \(path) is missing 'ClientId' and/or 'Domain' entries!")
            print("File currently has the following entries: \(values)")
            return nil
    }
    return (clientId: clientId, domain: domain)
}

public func isTokenValid(_ token: String, audience: String? = nil) -> Bool {
    
    let values = plistValues(bundle: Bundle.main)!
    let audience = audience ?? values.clientId
    let tokenValidator = IDTokenValidation(issuer: "https://\(values.domain)/", audience: audience)
    
    do {
        let jwt = try decode(jwt: token)
        return tokenValidator.validate(jwt)
    } catch {
        print("Invalid Token - Could not Decode")
        return false
    }
}
