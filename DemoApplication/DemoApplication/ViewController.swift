//
//  ViewController.swift
//  DemoApplication
//
//  Created by Daniel Saidi on 2017-08-20.
//  Copyright © 2017 Daniel Saidi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let env = ApiEnvironment.production
        let context = NonPersistentApiContext(environment: env)
        let baseService = AlamofireMovieService(context: context)
        let service = RealmMovieService(baseService: baseService)
        var invokeCount = 0
        service.getTopGrossingMovies(year: 2016) { (movies, error) in
            invokeCount += 1
            print("Found \(movies.count) movies (callback #\(invokeCount))")
        }
    }
}

