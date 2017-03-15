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

class AddSongViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, ModifyTracksQueueDelegate {
    
    // MARK: - Storyboard Variables

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var searchTracksField: UISearchBar!
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
        backgroundImageView.addBlur(withAlpha: 1, withStyle: .dark)
        setDelegates()
        initializeActivityIndicator()
        setupTopBar()
        adjustView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UINavigationBar.appearance().barTintColor = UIColor(red: 18/255, green: 20/255, blue: 65/255, alpha: 1)
    }
    
    // MARK: - Functions
    
    func setDelegates() {
        searchTracksField.delegate = self
        trackTableView.delegate   = self
        trackTableView.dataSource = self
    }
    
    func initializeActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.center = self.view.center
        view.addSubview(indicator)
    }
    
    func setupTopBar() {
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont(name: "Helvetica Light", size: 20)!, NSForegroundColorAttributeName: UIColor.white]
        navigationController?.navigationBar.barTintColor = UIColor(red: 0/255, green: 0/255, blue: 45/255, alpha: 1)
        
        searchTracksField.barTintColor = UIColor(red: 18/255, green: 19/255, blue: 65/255, alpha: 1)
        let textField = searchTracksField.value(forKey: "searchField") as? UITextField
        textField?.textColor = .white
        textField?.backgroundColor = UIColor(red: 26/255, green: 9/255, blue: 32/255, alpha: 1)
    }
    
    func adjustView() {
        trackTableView.backgroundColor = .clear
        trackTableView.separatorColor  = UIColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        trackTableView.tableFooterView = UIView()
        
        navigationItem.hidesBackButton = true
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let textEntered = searchBar.text!
        
        if !textEntered.isEmpty {
            fetchResults(forQuery: textEntered)
            searchBar.resignFirstResponder()
        }
    }
    
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
        return tracksList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        if tracksQueue(hasTrack: tracksList[indexPath.section]) {
            removeBlur(fromCell: cell)
            cell.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.7)
        } else {
            addBlur(toCell: cell)
            cell.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.3)
        }
    }
    
    func addBlur(toCell cell: UITableViewCell) {
        for everyView in cell.subviews {
            if let blurredView = everyView as? UIVisualEffectView {
                blurredView.removeFromSuperview()
            }
        }
        removeBlur(fromCell: cell)
        cell.makeBorder()
    }
    
    func removeBlur(fromCell cell: UITableViewCell) {
        for everyView in cell.subviews {
            if let blurredView = everyView as? UIVisualEffectView {
                blurredView.removeFromSuperview()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "Track", for: indexPath) as! TrackTableViewCell
        
        // MARK: - Cell Properties
        cell.trackName.text = tracksList[indexPath.section].name
        cell.artistName.text = tracksList[indexPath.section].artist

        if let unwrappedArtwork = tracksList[indexPath.section].artwork {
            cell.artworkImageView.image = unwrappedArtwork
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        addToQueue(track: tracksList[indexPath.section])
        self.removeBlur(fromCell: cell)
        
        UIView.animate(withDuration: 0.35) {
            cell.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.7)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        removeFromQueue(track: tracksList[indexPath.section])
        self.addBlur(toCell: cell)
        
        UIView.animate(withDuration: 0.35) {
            cell.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.3)
        }
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
        return 110
    }
}
