//
//  RealmMovie.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import RealmSwift

class RealmMovie: Object, Movie {
    
    convenience required public init(copy obj: Movie) {
        self.init()
        id = obj.id
        name = obj.name
        year = obj.year
        releaseDate = obj.releaseDate
        grossing = obj.grossing
        rating = obj.rating
        _cast.append(contentsOf: obj.cast.map { RealmActor(copy: $0) })
    }
    
    
    dynamic var id = 0
    dynamic var name = ""
    dynamic var year = 0
    dynamic var releaseDate = Date(timeIntervalSince1970: 0)
    dynamic var grossing = 0
    dynamic var rating = 0.0
    var cast: [Actor] { return Array(_cast) }
    
    private var _cast = List<RealmActor>()
    
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
