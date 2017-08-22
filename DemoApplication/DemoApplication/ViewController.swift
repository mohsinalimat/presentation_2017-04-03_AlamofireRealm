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
        movieService.getMovie(id: 1) { (movie, error) in
            print(movie)
        }
    }
    
    lazy var movieService: MovieService = IoC.resolve()
}

