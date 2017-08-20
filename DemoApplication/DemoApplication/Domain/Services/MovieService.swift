//
//  MovieService.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-20.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

typealias MoviesResult = (_ movies: [Movie], _ error: Error?) -> ()


protocol MovieService: class {
    
    func getBestRatedMovies(year: Int, completion: @escaping MoviesResult)
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult)
}
