//
//  ApiActor.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-21.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import ObjectMapper

class ApiActor: NSObject, Actor, Mappable {
    
    required public init?(map: Map) {
        super.init()
    }
    
    var name = ""
    
    func mapping(map: Map) {
        name <- map["name"]
    }
}
