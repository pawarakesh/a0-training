//
//  ViewController.swift
//  exercise-02
//
//  Created by Martin Walsh on 22/11/2018.
//  Copyright © 2018 Auth0. All rights reserved.
//

import UIKit
import Auth0

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func actionLogin(_ sender: Any) {
        Auth0
            .webAuth()
            .scope("openid profile")
            .logging(enabled: true)
            .start { response in
                switch(response) {
                case .success(let result):
                    print("Authentication Success")
                    print("Access Token: \(result.accessToken ?? "No Access Token Found")")
                    print("ID Token: \(result.idToken ?? "No ID Token Found")")
                    print("Token Valid: \(isTokenValid(result.idToken!))")
                case .failure(let error):
                    print("Authentication Failed: \(error)")
                }
        }
    }
    
    @IBAction func actionAPI(_ sender: Any) {
        print("Call API")
    }
    
}

