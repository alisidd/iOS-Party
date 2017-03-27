//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class AddSongViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Storyboard Variables

    @IBOutlet weak var searchTracksField: UITextField!
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
        setDelegates()
        initializeActivityIndicator()
        adjustViews()
    }
    
    // MARK: - Functions
    
    func setDelegates() {
        searchTracksField.delegate = self
        trackTableView.delegate    = self
        trackTableView.dataSource  = self
    }
    
    func initializeActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.center = view.center
        view.addSubview(indicator)
    }
    
    func adjustViews() {
        trackTableView.backgroundColor = .clear
        trackTableView.tableFooterView = UIView()
        
        navigationItem.hidesBackButton = true
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchTracksField.resignFirstResponder()
        if !searchTracksField.text!.isEmpty {
            fetchResults(forQuery: searchSongsField.text!)
        }
        return true
    }
    
    func fetchResults(forQuery query: String) {
        indicator.startAnimating()
        makeRequestForTracks(forQuery: query)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.APIManager.dispatchGroup.wait()
            self.populateTracksList()
            self.scrollBackUp()
        }
    }
    
    func makeRequestForTracks(forQuery query: String) {
        if party.musicService == .appleMusic {
            APIManager.makeHTTPRequestToApple(withString: query, withPossibleTrackID: nil)
        } else {
            APIManager.makeHTTPRequestToSpotify(withString: query)
        }
    }
    
    func scrollBackUp() {
        DispatchQueue.main.async {
            if !self.tracksList.isEmpty {
                self.trackTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
    
    func populateTracksList() {
        tracksList = APIManager.tracksList
        DispatchQueue.main.async {
            if self.tracksList.isEmpty {
                self.displayNoTracksFoundLabel()
            } else {
                self.removeNoTracksFoundLabel()
                self.fetchRestOfTracks()
            }
        }
    }
    
    func displayNoTracksFoundLabel() {
        customizeLabel()
        view.addSubview(noTracksFoundLabel)
    }
    
    func customizeLabel() {
        noTracksFoundLabel.text = "No Tracks Found"
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = view.center
    }
    
    func removeNoTracksFoundLabel() {
        noTracksFoundLabel.removeFromSuperview()
    }
    
    func fetchRestOfTracks() {
        let tracksCaptured = tracksList
        DispatchQueue.global(qos: .userInitiated).async {
            if self.tracksList.count >= 10 {
                for i in 10..<self.tracksList.count {
                    if tracksCaptured == self.tracksList {
                        let artworkFetched = self.APIManager.fetchImage(fromURL: self.tracksList[i].lowResArtworkURL)
                        DispatchQueue.main.async {
                            if tracksCaptured == self.tracksList {
                                if let artworkFetchedUnwrapped = artworkFetched {
                                    self.tracksList[i].artwork = artworkFetchedUnwrapped
                                    self.trackTableView.reloadData()
                                }
                            }
                        }
                    } else {
                        break
                    }
                }
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
        cell.backgroundColor = .clear
        if tracksQueue(hasTrack: tracksList[indexPath.row]) || tracksQueue.contains(tracksList[indexPath.row]) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
    }
    
    func tracksQueue(hasTrack track: Track) -> Bool {
        for trackInQueue in party.tracksQueue {
            if track.id == trackInQueue.id {
                return true
            }
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "Track", for: indexPath) as! TrackTableViewCell
        
        // Cell Properties
        cell.trackName.text = tracksList[indexPath.row].name
        cell.artistName.text = tracksList[indexPath.row].artist

        if let unwrappedArtwork = tracksList[indexPath.row].artwork {
            cell.artworkImageView.image = unwrappedArtwork
        } else {
            cell.artworkImageView.image = nil
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        
        addToQueue(track: tracksList[indexPath.row])
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .checkmark
        }
    }
    
    func addToQueue(track: Track) {
        tracksQueue.append(track)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        removeFromQueue(track: tracksList[indexPath.row])
        
        if !tracksQueue(hasTrack: tracksList[indexPath.row]) {
            UIView.animate(withDuration: 0.35) {
                cell.accessoryType = .none
            }
        }
    }
    
    func removeFromQueue(track: Track) {
        for trackInQueue in tracksQueue {
            if trackInQueue.id == track.id {
                tracksQueue.remove(at: tracksQueue.index(of: trackInQueue)!)
            }
        }
    }
}
