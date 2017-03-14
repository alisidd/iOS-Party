//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

protocol ModifyTracksQueueDelegate: class {
    func addToQueue(track: Track)
    func removeFromQueue(track: Track)
}

class AddSongViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ModifyTracksQueueDelegate {
    
    // MARK: - Storyboard Variables

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var searchTracksField: UISearchBar!
    @IBOutlet weak var searchView: UIView!
    //@IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var trackTableView: UITableView!
    
    // MARK: - General Variables
    
    var party = Party()
    private var tracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.trackTableView.reloadData()
                self.indicator.stopAnimating()
                self.indicator.hidesWhenStopped = true
            }
        }
    }
    var tracksQueue = [Track]()
    private let APIManager = RestApiManager()
    private var indicator = UIActivityIndicatorView()
    private let noTracksFoundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 350, height: 30))
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backgroundImageView.addBlur(withAlpha: 1)
        setDelegates()
        initializeActivityIndicator()
        setupNavigationBar()
        adjustView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //customizeTextField()
        customizeSearchField()
        UINavigationBar.appearance().barTintColor = UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1)
    }
    
    // MARK: - Functions
    
    func setDelegates() {
        //searchTracksField.delegate = self
        trackTableView.delegate   = self
        trackTableView.dataSource = self
    }
    
    func initializeActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.center = self.view.center
        view.addSubview(indicator)
    }
    
    func setupNavigationBar() {
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont(name: "Helvetica Light", size: 20)!, NSForegroundColorAttributeName: UIColor.white]
    }
    
    func adjustView() {
        trackTableView.backgroundColor = .clear
        trackTableView.separatorColor  = UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        trackTableView.tableFooterView = UIView()
        trackTableView.allowsSelection = false
        
        navigationItem.hidesBackButton = true
    }
    
    func customizeSearchField() {
        if let field = searchTracksField.value(forKey: "searchField") as? UITextField {
            field.textColor = UIColor.white
        }
    }
    
    /*
    func customizeTextField() {
        searchTracksField.attributedPlaceholder = NSAttributedString(string: "Search Tracks", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        searchTracksField.layer.borderWidth = 1.5
        
        searchTracksField.autocapitalizationType = UITextAutocapitalizationType.sentences
        searchTracksField.returnKeyType = .search
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchSongsField.resignFirstResponder()
        if !(searchSongsField.text?.isEmpty)! {
            fetchResults(forQuery: searchSongsField.text!)
        }
        return true
    }*/
    
    func fetchResults(forQuery query: String) {
        indicator.startAnimating()
        if party.musicService == .appleMusic {
            APIManager.makeHTTPRequestToApple(withString: query)
        } else {
            APIManager.makeHTTPRequestToSpotify(withString: query)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.APIManager.dispatchGroup.wait()
            self.tracksList = self.APIManager.tracksList
            if self.tracksList.count == 0 {
                DispatchQueue.main.async {
                    self.displayNoTracksFoundLabel()
                }
            } else {
                DispatchQueue.main.async {
                    self.removeNoTracksFoundLabel()
                }
            }
        }
    }
    
    func displayNoTracksFoundLabel() {
        noTracksFoundLabel.text = "No Tracks Found"
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = view.center
        view.addSubview(noTracksFoundLabel)
    }
    
    func removeNoTracksFoundLabel() {
        noTracksFoundLabel.removeFromSuperview()
    }
    
    func addToQueue(track: Track) {
        tracksQueue.append(track)
    }
    
    func removeFromQueue(track: Track) {
        for trackInQueue in tracksQueue {
            if trackInQueue.id == track.id {
                tracksQueue.remove(at: tracksQueue.index(of: trackInQueue)!)
            }
        }
    }
    
    // MARK: - Navigation

    func emptyArrays() {
        tracksList.removeAll()
        tracksQueue.removeAll()
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracksList.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackTableViewCell
        cell.delegate = self
        
        // MARK: - Cell Properties
        
        cell.track = (tracksList[indexPath.row])
        cell.trackName.text = tracksList[indexPath.row].name
        cell.artistName.text = tracksList[indexPath.row].artist

        if let unwrappedArtwork = tracksList[indexPath.row].artwork {
            cell.artworkImageView.image = unwrappedArtwork
        }
        
        // MARK: - Cell Selection
        
        if (tracksQueue(hasTrack: (tracksList[indexPath.row]))) {
            cell.addButton.setTitle("✓", for: .normal)
        } else {
            cell.addButton.setTitle("+", for: .normal)
        }
        
        return cell
    }
    
    func tracksQueue(hasTrack track: Track) -> Bool {
        for trackInQueue in tracksQueue {
            if track.id == trackInQueue.id {
                return true
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
