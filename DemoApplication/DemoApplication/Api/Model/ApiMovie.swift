//
//  ApiMovie.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-21.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import ObjectMapper

class ApiMovie: Movie, Mappable {
    
    required public init?(map: Map) {}
    
    var id = 0
    var name = ""
    var releaseDate = Date(timeIntervalSince1970: 0)
    var grossing = 0
    var rating = 0.0
    var _cast = [ApiActor]()
    var cast = [Actor]()
    
    func mapping(map: Map) {
        name <- map["name"]
        releaseDate <- (map["releaseDate"], DateTransform.custom)
        grossing <- map["grossing"]
        rating <- map["rating"]
        _cast <- map["cast"]
        cast = _cast
    }
}
