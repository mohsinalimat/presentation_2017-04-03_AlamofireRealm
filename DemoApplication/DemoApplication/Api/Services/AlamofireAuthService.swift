//
//  AlamofireAuthService.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper

class AlamofireAuthService: AlamofireService, AuthService {
    
    func authorizeApplication(completion: @escaping AuthResult) {
        get(at: .auth).responseString {
            (res: DataResponse<String>) in
            if let token = res.result.value {
                self.context.authToken = token
            }
            completion(res.result.value, res.result.error)
        }
    }
}
