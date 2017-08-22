//
//  AlamofireMovieService.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-22.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import Alamofire
import AlamofireObjectMapper

class AlamofireMovieService: AlamofireService, MovieService {
    
    func getMovie(id: Int, completion: @escaping MovieResult) {
        get(at: .movie(id: id)).responseObject {
            (res: DataResponse<ApiMovie>) in
            completion(res.result.value, res.result.error)
        }
    }
    
    func getTopGrossingMovies(year: Int, completion: @escaping MoviesResult) {
        get(at: .topGrossingMovies(year: year)).responseArray {
            (res: DataResponse<[ApiMovie]>) in
            completion(res.result.value ?? [], res.result.error)
        }
    }
    
    func getTopRatedMovies(year: Int, completion: @escaping MoviesResult) {
        get(at: .topRatedMovies(year: year)).responseArray {
            (res: DataResponse<[ApiMovie]>) in
            completion(res.result.value ?? [], res.result.error)
        }
    }
}
