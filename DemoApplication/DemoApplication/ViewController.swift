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
        reloadData(self)
    }
    
    
    lazy var movieService: MovieService = IoC.resolve()
    
    
    fileprivate var movies = [Movie]()
    
    
    @IBOutlet weak var tableView: UITableView? {
        didSet {
            tableView?.delegate = self
            tableView?.dataSource = self
        }
    }
    
    @IBOutlet weak var dataPicker: UISegmentedControl?
    
    
    @IBAction func reloadData(_ sender: Any) {
        let index = dataPicker?.selectedSegmentIndex ?? 0
        index == 0
            ? movieService.getTopGrossingMovies(year: 2016, completion: moviesCompletion)
            : movieService.getTopRatedMovies(year: 2016, completion: moviesCompletion)
    }
    
    fileprivate func moviesCompletion(_ movies: [Movie], _ error: Error?) {
        if let error = error { fatalError(error.localizedDescription) }
        self.movies = movies
        self.tableView?.reloadData()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let movie = movies[indexPath.row]
        let names = movie.cast.map { $0.name }
        cell.textLabel?.text = "\(movie.name) (\(movie.year))"
        cell.detailTextLabel?.text = names.joined(separator: ", ")
        return cell
    }
}
