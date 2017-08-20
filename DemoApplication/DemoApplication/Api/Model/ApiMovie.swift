//
//  ApiMovie.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-21.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import ObjectMapper

class ApiMovie: NSObject, Movie {
    
    required public init?(map: Map) {
        super.init()
    }
    
    var name = ""
    var releaseDate = Date(timeIntervalSince1970: 0)
    var grossing = 0
    var rating = 0.0
    fileprivate var _cast = [ApiActor]()
    var cast = [Actor]()
}


extension ApiMovie: Mappable {
    
    func mapping(map: Map) {
        
        name <- map["name"]
        releaseDate <- (map["releaseDate"], DateTransform())
        grossing <- map["grossing"]
        rating <- map["grossing"]
        _cast <- map["cast"]
        cast = _cast
    }
}
