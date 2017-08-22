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
        let service = AlamofireMovieService(context: context)
        service.getTopGrossingMovies(year: 2016) { (movies, error) in
            if let error = error {
                return print(error.localizedDescription)
            }
            print("Found \(movies.count) movies:")
            movies.forEach { print($0.name) }
        }
    }
}

