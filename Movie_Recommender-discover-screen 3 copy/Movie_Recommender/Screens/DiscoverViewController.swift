//
//  DiscoverViewController.swift
//  Movie_Recommender
//
//  Created by Fnu Tsering on 3/14/22.
//
// Testing to see if i fixed the problems

import UIKit
import AlamofireImage

class DiscoverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    
    var trendingList = [[String:Any]]() // instance variable to save the data returned by API request
    var popularList = [[String:Any]]()
    var upcomingList = [[String:Any]]()
    var add_count = 0
    
    var trendingListAll = [[String:Any]]() // instance variable to save the data returned by API request
    var popularListAll = [[String:Any]]()
    var upcomingListAll = [[String:Any]]()
    var movie_categoriesWithAll = Array(repeating: [[String:Any]](), count: 3)
    
    //    var movie_categories = [[[String:Any]]]() //this dict will contain the names of movie categories as key and the movies arrays of dicts as value.
    var movie_categories = Array(repeating: [[String:Any]](), count: 3)
    //To create an array of specific size in Swift, use Array initialiser syntax and pass this specific size. We also need to pass the default value for these elements in the Array. To use Array initialiser syntax, we need to specify repeating or default value, and the count
    var movie_groups = ["Trending Movies", "Popular Movies", "Upcoming Movies"] //title of our sections
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let api_key = "425089d4394daaa7a241ed4b96a4c194"
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self //specifying the data will come from this view controller
        tableView.delegate = self
        getTrendingMovies()
        getPopularMovies()
        getUpcomingMovies()
    }
    
    
    // MARK: - TableView methods
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350 //height of tableView row
    }
    
    // Number of sections
    func numberOfSections(in tableView: UITableView) -> Int {
        return movie_categories.count
    }
    
    // Creates customized view for the table view section headers
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let sectionHeaderView = UIView() // view for the section headers
        
        let sectionHeaderLabel = UILabel()
        sectionHeaderLabel.text = movie_groups[section]
        sectionHeaderLabel.textColor = .white
        sectionHeaderLabel.font = UIFont.boldSystemFont(ofSize: 25.0) 
        sectionHeaderLabel.frame = CGRect(x: 20, y: 5, width: 250, height: 40)
        sectionHeaderView.addSubview(sectionHeaderLabel)
        
        // View All button configuration
        let viewAllButton = UIButton()
        viewAllButton.frame = CGRect(x: 330, y: 5, width: 60, height: 30)
        viewAllButton.setTitle("View All", for: .normal)
        viewAllButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15) // customize font size
        viewAllButton.tag = section //set the button's tag as section number where the button is/is clicked
        viewAllButton.addTarget(self, action: #selector(viewAllButtonClicked(sender:)), for: .touchUpInside)
        sectionHeaderView.addSubview(viewAllButton) // add the button to the header view
        
        return sectionHeaderView
    }
    
    // Function called when the View All button is tapped in a section header
    @objc func viewAllButtonClicked(sender: UIButton){
        //tag will contain the section number of where the button is
        let movies_list = movie_categoriesWithAll[sender.tag]
        let section_title = movie_groups[sender.tag]
        let movie_category = [section_title: movies_list]
        
        // the prepare for segue function is called first with the parameters before the segue is performed.
        self.performSegue(withIdentifier: "discoverToViewAll", sender: movie_category)
    }
    
    // Number of rows in section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Table view cell config
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DiscoverTableCell", for: indexPath) as! DiscoverTableCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
        return cell
    }
    
    // Setting the dataSource and delegate for the collection view cell to the table view controller so that the collection view can access and display the API data retrieved in this table view controller class
    //    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    //
    //        guard let tableViewCell = cell as? DiscoverTableCell else { return }
    //        print("setting the data")
    //        print(indexPath.section)
    //        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.section)
    //    }
    
    
    // MARK: - Collection view configuratiion
    
    // Sets the number of movies to display in each section of the table view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //        print("IN COLLECTON VIEW NUM of MOVIES ")
        //        print(collectionView.tag) //prints correct
        return movie_categories[collectionView.tag].count
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiscoverCollectionCell", for: indexPath) as! DiscoverCollectionCell
        
        let movie_list = movie_categories[collectionView.tag]
        let movie = movie_list[indexPath.row]
        if movie["title"] != nil {
            cell.movieLabel.text = (movie["title"] as! String)
        } else {
            cell.movieLabel.text = (movie["name"] as! String)
        }
        //      From TMDB doc: To build an image URL, you will need 3 pieces of data. The base_url, size and file_path. Simply combine them all and you will have a fully qualified URL.
        let img_base_url = "https://image.tmdb.org/t/p/"
        let poster_size = "w185" //w342
        let poster_path = movie["poster_path"] as! String
        let imgURLString = (img_base_url + poster_size + poster_path)
        let imgURL = URL(string: imgURLString)
        
        cell.imageView.af.setImage(withURL: imgURL!) //URL is an optional object so force unwrap
        return cell
    }
    
    // This function is called when the user selects an item(movie) in the collection View
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = movie_categories[collectionView.tag][indexPath.row]
        //        print(type(of: movie))
        self.performSegue(withIdentifier: "discoverToDetails", sender: movie)
    }
    
    // MARK: - API Requests Methods
    
    // This function gets a list of trending movies from the TMDB API and loads the tableview with the data
    func getTrendingMovies() {
        let urlString = "https://api.themoviedb.org/3/trending/all/day?api_key=\(api_key)" //url String
        let url = URL(string: urlString)!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession.shared // shared URLSessions uses the default config
        
        // Note: URLSession is asychronous so the request is sent on a background thread.
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                
                // parses json data to dict
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                let trendingMovies = dataDictionary["results"] as! [[String: Any]] // gets just the array of movies
                for movie in trendingMovies {
                    if movie["media_type"] as! String == "movie" {
                        self.trendingListAll.append(movie)
                    }
                }
                
                // slices the trendingListAll array to get just the first 10 movies
                self.trendingList = Array(self.trendingListAll.prefix(upTo: 10))
                self.movie_categories[0] = self.trendingList
                // adds the list to this array at index 0 which is also the section number of the trending list on the table view
                self.movie_categoriesWithAll[0] = self.trendingListAll
                
                // Anything related to the UI must be performed on the main thread,
                // therefore use DispatchQueue.main.async to switch back to the main thread.
                DispatchQueue.main.async {
                    //recalls the table view functions to reload the table view with new data
                    self.tableView.reloadData()
                }
            }
        }
        task.resume() // starts the data task which sends the request to the server on a background thread.
    }
    
    
    // So the app is immediately free to continue - meaning URLSession is asychronous.
    //        print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
    
    func getPopularMovies() {
        let urlString = "https://api.themoviedb.org/3/movie/popular?api_key=\(api_key)" //url String
        let url = URL(string: urlString)!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession.shared //URL session is asynchronous so the session runs on a background thread
        let task = session.dataTask(with: request) { (data, response, error) in
            // This will run when the network request returns
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                //                print(dataDictionary)
                //                self.popularList = dataDictionary["results"] as! [[String : Any]]
                self.popularListAll = dataDictionary["results"] as! [[String : Any]]
                self.popularList = Array(self.popularListAll.prefix(upTo: 10)) // gets only the first 10 movies returned by API
                //                print(self.popularList)
                self.movie_categories[1] = self.popularList
                self.movie_categoriesWithAll[1] = self.popularListAll
                
                DispatchQueue.main.async {
                    print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                    self.tableView.reloadData()
                    //recall the table view functions to reloads the table view with new data
                }
            }
        }
        task.resume()
        
    }
    
    
    func getUpcomingMovies() {
        let urlString = "https://api.themoviedb.org/3/movie/upcoming?api_key=\(api_key)" //url String
        let url = URL(string: urlString)!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            // This will run when the network request returns
            if let error = error {
                print(error.localizedDescription)
            } else if let data = data {
                let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                
                self.upcomingListAll = dataDictionary["results"] as! [[String : Any]]
                self.upcomingList = Array(self.upcomingListAll.prefix(upTo: 10)) // gets only the first 10 movies returned by API
                //                print(self.upcomingList)
                self.movie_categories[2] = self.upcomingList
                self.movie_categoriesWithAll[2] = self.upcomingListAll
                
                // Completion handler closure is performed on a background thread.
                // Anything related to the UI must be performed on the main thread,
                // therefore use DispatchQueue.main.async to switch back to the main thread.
                DispatchQueue.main.async {
                    print("On main thread? " + (Thread.current.isMainThread ? "Yes" : "No"))
                    self.tableView.reloadData()
                    //recall the table view functions to reloads the table view with new data
                }
            }
        }
        task.resume()
        
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "discoverToDetails" {
            let detailsVC = segue.destination as! MovieDetailsViewController
            detailsVC.movieSelected = sender as! [String:Any]?// note that the movie was passed as argument for sender
        }
        else if segue.identifier == "discoverToViewAll" {
            let viewMoreVC = segue.destination as! ViewMoreViewController
            viewMoreVC.movies_list = sender as! [String: [[String:Any]]]?
        }
        // Note:
        // fixed a problem of the segue screen loading twice by
        // recreating the segue so it connects the view controller
        // to the details view controller rather than from the cell
        // to the details vc
    }
    
    
    // MARK: - Search Bar methods
    //    func updateSearchResults(for searchController: UISearchController) {
    //        // makes sure query is not nil
    //        let query = searchController.searchBar.text! as String
    //        if !query.isEmpty {
    //            getSearchResults(query: query)
    //            let resultController = searchController.searchResultsController as! SearchResultsViewController
    //            resultController.results = searchResults
    //        }
    //    }
    //    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    //        searchBar.text = ""
    //        searchBar.resignFirstResponder() // dismisses keyboard
    //    }
    //
    //    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    //        if !searchBar.text?.isEmpty {
    //            let query = searchBar.text!
    //            getSearchResults(query: query)
    //
    //        }
    //    }
    
}
