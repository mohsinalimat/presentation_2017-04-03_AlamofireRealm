//
//  ApiRoute.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-21.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

enum ApiRoute { case
    
    auth,
    topGrossingMovies(year: Int),
    topRatedMovies(year: Int)
}


extension ApiRoute {
    
    var path: String {
        switch self {
        case .auth: return "TBD"
        case .topGrossingMovies(let year): return "movies/\(year)/grossing"
        case .topRatedMovies(let year): return "movies/\(year)/rating"
        }
    }
    
    var shouldRetryAfterAuth: Bool {
        switch self {
        case .auth: return false
        default: return true
        }
    }
}


extension ApiRoute {
    
    func url(for environment: ApiEnvironment) -> String {
        return "\(environment.url)/\(path)"
    }
}
