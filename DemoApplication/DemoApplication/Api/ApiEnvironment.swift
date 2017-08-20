//
//  ApiEnvironment.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-21.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

enum ApiEnvironment: String { case
    
    prod = "http://danielsaidi.com/CocoaHeads-2017-04-03-Alamofire-Realm/api/"
}


extension ApiEnvironment {
    
    var url: String {
        return rawValue
    }
}
