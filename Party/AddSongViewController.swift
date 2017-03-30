//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class AddSongViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Storyboard Variables

    @IBOutlet weak var recommendationsLabel: UILabel!
    @IBOutlet weak var recommendationsCollectionView: UICollectionView!
    
    @IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var trackTableView: UITableView!
    
    // MARK: - General Variables
    
    var party = Party()
    private var recommendedTracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.recommendationsCollectionView.reloadData()
                self.indicator.stopAnimating()
                self.indicator.hidesWhenStopped = true
            }
        }
    }
    
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
    private let noTracksFoundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 320, height: 70))
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        initializeActivityIndicator()
        adjustViews()
        populateRecommendations()
    }
    
    // MARK: - Functions
    
    func setDelegates() {
        recommendationsCollectionView.delegate = self
        recommendationsCollectionView.dataSource = self
        
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
        recommendationsCollectionView.showsHorizontalScrollIndicator = false
        recommendationsCollectionView.allowsMultipleSelection = true
        
        trackTableView.backgroundColor = .clear
        trackTableView.tableFooterView = UIView()
        
        navigationItem.hidesBackButton = true
    }
    
    func populateRecommendations() {
        if party.tracksQueue.isEmpty {
            recommendationsLabel.isHidden = true
        } else {
            recommendationsLabel.isHidden = false
            indicator.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async {
                self.APIManager.makeHTTPRequestToSpotifyForRecommendations(withTracks: self.party.tracksQueue, forDanceability: self.party.danceability)
                self.APIManager.dispatchGroup.wait()
                print("Got all tracks")
                self.fetchImagesForFirstThree()
                print("Got all pics")
                self.recommendedTracksList = self.APIManager.tracksList
            }
        }
    }
    
    func fetchImagesForFirstThree() {
        for index in 0..<3 {
            if let track = self.APIManager.tracksList[safe: index] {
                if let url = track.mediumResArtworkURL {
                    track.mediumResArtwork = self.APIManager.fetchImage(fromURL: url)
                    print("Quick fetched artwork for \(track.name)")
                }
            }
        }
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
        hideCollectionsViews()
        showTableView()
        makeRequestForTracks(forQuery: query)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.APIManager.dispatchGroup.wait()
            self.populateTracksList()
            self.scrollBackUp()
        }
    }
    
    func hideCollectionsViews() {
        UIView.animate(withDuration: 0.5, animations: {
            self.recommendationsLabel.alpha = 0
            self.recommendationsCollectionView.alpha = 0
        }) { (finished) in
            self.recommendationsLabel.isHidden = true
            self.recommendationsCollectionView.isHidden = true
        }
    }
    
    func showTableView() {
        trackTableView.isHidden = false
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
                self.displayNoTracksLabel(with: "No Tracks Found")
            } else {
                self.removeNoTracksFoundLabel()
                self.fetchRestOfTracks()
            }
        }
    }
    
    func displayNoTracksLabel(with labelText: String) {
        customizeLabel(with: labelText)
        view.addSubview(noTracksFoundLabel)
    }
    
    func customizeLabel(with labelText: String) {
        noTracksFoundLabel.text = labelText
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = view.center
        noTracksFoundLabel.lineBreakMode = .byWordWrapping
        noTracksFoundLabel.numberOfLines = 0
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
    
    // MARK: - Recommendation Table View
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendedTracksList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Recommendation Cell", for: indexPath) as! RecommendedCollectionViewCell
        
        let trackToAdd = recommendedTracksList[indexPath.row]
        
        if let url = trackToAdd.mediumResArtworkURL {
            if let image = trackToAdd.mediumResArtwork {
                cell.artworkImageView.image = image
            } else {
                cell.artworkImageView.image = nil
                DispatchQueue.global(qos: .userInitiated).async {
                    trackToAdd.mediumResArtwork = self.APIManager.fetchImage(fromURL: url)
                    DispatchQueue.main.async {
                        cell.artworkImageView.image = trackToAdd.mediumResArtwork
                        self.recommendationsCollectionView.reloadData()
                    }
                }
            }
        } else {
            cell.artworkImageView.image = trackToAdd.artwork ?? nil
        }
        
        cell.trackName.text = trackToAdd.name
        cell.artistName.text = trackToAdd.artist
        
        if partyTracksQueue(hasTrack: recommendedTracksList[indexPath.row]) || tracksQueue.contains(recommendedTracksList[indexPath.row]) {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: .init(rawValue: 0))
            setCheckmark(for: cell, at: indexPath)
        } else {
            removeCheckmark(for: cell)
        }
        
        return cell
    }
    
    func setCheckmark(for cell: RecommendedCollectionViewCell, at indexPath: IndexPath) {
        print("Setting checkmark")
        DispatchQueue.main.async {
            cell.checkmarkLabel.text = "✓"
        }
    }
    
    func removeCheckmark(for cell: RecommendedCollectionViewCell) {
        print("Removing checkmark")
        cell.checkmarkLabel.text = ""
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! RecommendedCollectionViewCell
        setCheckmark(for: cell, at: indexPath)
        
        let trackToAdd = self.recommendedTracksList[indexPath.row]
        addToQueue(track: trackToAdd)
        
        DispatchQueue.global(qos: .userInitiated).async {
            trackToAdd.artwork = self.APIManager.fetchImage(fromURL: trackToAdd.lowResArtworkURL)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! RecommendedCollectionViewCell
        
        if !partyTracksQueue(hasTrack: recommendedTracksList[indexPath.row]) {
            removeCheckmark(for: cell)
            removeFromQueue(track: recommendedTracksList[indexPath.row])
        }
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
        if partyTracksQueue(hasTrack: tracksList[indexPath.row]) || tracksQueue.contains(tracksList[indexPath.row]) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
    }
    
    func partyTracksQueue(hasTrack track: Track) -> Bool {
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
        if !partyTracksQueue(hasTrack: track) && !tracksQueue.contains(track) {
            tracksQueue.append(track)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        removeFromQueue(track: tracksList[indexPath.row])
        
        if !partyTracksQueue(hasTrack: tracksList[indexPath.row]) {
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
