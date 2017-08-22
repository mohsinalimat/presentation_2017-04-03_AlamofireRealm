//
//  RealmActor.swift
//  DemoApplication
//
//  Created by Saidi Daniel (BookBeat) on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import RealmSwift

class RealmActor: Object, Actor {
    
    convenience required public init(copy obj: Actor) {
        self.init()
        name = obj.name
    }
    
    
    dynamic var name = ""
    
    
    override class func primaryKey() -> String? {
        return "name"
    }
}
