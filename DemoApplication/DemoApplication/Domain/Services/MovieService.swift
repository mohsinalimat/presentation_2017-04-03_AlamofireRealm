//
//  MovieService.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-20.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Foundation

typealias MovieResult = (_ movie: Movie?, _ error: Error?) -> ()
typealias MoviesResult = (_ movies: [Movie], _ error: Error?) -> ()


protocol MovieService: class {
    
    func getMovie(id: Int, completion: @escaping MovieResult)
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult)
    func getTopRatedMovies(year: Int, completion: @escaping MoviesResult)
}
