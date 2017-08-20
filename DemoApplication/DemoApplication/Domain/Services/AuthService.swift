//
//  AuthService.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-20.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

typealias AuthResult = (_ authToken: String?, _ error: Error?) -> ()


protocol AuthService: class {
    
    func authorizeApplication(_ completion: @escaping AuthResult)
}
