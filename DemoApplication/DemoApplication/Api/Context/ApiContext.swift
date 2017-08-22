//
//  ApiContext.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-21.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

protocol ApiContext: class {
    
    var authToken: String? { get set }
    var environment: ApiEnvironment { get set }
}
