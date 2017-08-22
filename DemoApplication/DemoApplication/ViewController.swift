//
//  ViewController.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-20.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let env = ApiEnvironment.production
        let context = NonPersistentApiContext(environment: env)
        let baseService = AlamofireMovieService(context: context)
        let movieService = RealmMovieService(baseService: baseService)
        
        let authService = AlamofireAuthService(context: context)
        let sessionManager = SessionManager.default
        sessionManager.adapter = ApiRequestAdapter(context: context)
        sessionManager.retrier = ApiRequestRetrier(context: context, authService: authService)
        
        movieService.getMovie(id: 1) { (movie, error) in
            print(movie)
        }
    }
}

