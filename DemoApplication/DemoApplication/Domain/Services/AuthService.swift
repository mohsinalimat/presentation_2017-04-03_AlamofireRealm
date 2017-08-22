//
//  AuthService.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

typealias AuthResult = (_ token: String?, _ error: Error?) -> ()


protocol AuthService: class {

    func authorizeApplication(completion: @escaping AuthResult)
}
