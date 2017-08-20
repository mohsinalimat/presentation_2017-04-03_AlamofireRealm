//
//  Movie.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-20.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

protocol Movie {
    
    var name: String { get }
    var releaseDate: Date { get }
    var averageRating: Double { get }
    var cast: [Actor] { get }
}
