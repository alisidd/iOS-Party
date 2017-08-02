//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

class AddSongViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    // MARK: - Storyboard Variables

    @IBOutlet weak var recommendationsLabel: UILabel!
    @IBOutlet weak var recommendationsCollectionView: UICollectionView!
    
    @IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var tracksCounter: BadgeSwift!
    
    @IBOutlet weak var trackTableView: UITableView!
    
    // MARK: - General Variables
    
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
                self.fetchImageForRestOfTracks()
            }
        }
    }
    var tracksSelected = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.tracksCounter.isHidden = !(self.tracksSelected.count > 0)
                self.tracksCounter.text = String(self.tracksSelected.count)
            }
        }
    }
    private lazy var fetcher: Fetcher = Party.musicService == .spotify ? SpotifyFetcher() : AppleMusicFetcher()
    private var indicator = UIActivityIndicatorView()
    private let noTracksFoundLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 320, height: 70))
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        initializeActivityIndicator()
        adjustViews()
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
        fetcher.searchCatalog(forTerm: query)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.fetcher.dispatchGroup.wait()
            
            self?.populateTracksList()
            self?.scrollBackUp()
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
    
    func scrollBackUp() {
        DispatchQueue.main.async {
            if !self.tracksList.isEmpty {
                self.trackTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
    
    func populateTracksList() {
        tracksList = fetcher.tracksList
        DispatchQueue.main.async {
            if self.tracksList.isEmpty {
                self.displayNoTracksLabel(with: "No Tracks Found")
            } else {
                self.removeNoTracksFoundLabel()
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
    
    func fetchImageForRestOfTracks() {
        let tracksCaptured = tracksList
        DispatchQueue.global(qos: .userInitiated).async {
            for track in self.tracksList {
                if track.lowResArtwork == nil && self.tracksList == tracksCaptured {
                    let artworkFetched = Track.fetchImage(fromURL: track.lowResArtworkURL)
                    DispatchQueue.main.async {
                        if let artworkFetched = artworkFetched, tracksCaptured == self.tracksList {
                            track.lowResArtwork = artworkFetched
                            self.trackTableView.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Navigation

    func emptyArrays() {
        tracksList.removeAll()
        tracksSelected.removeAll()
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
        
        if let image = trackToAdd.lowResArtwork {
            cell.artworkImageView.image = image
        } else {
            cell.artworkImageView.image = nil
            DispatchQueue.global(qos: .userInitiated).async {
                trackToAdd.lowResArtwork = Track.fetchImage(fromURL: trackToAdd.lowResArtworkURL)
                DispatchQueue.main.async {
                    cell.artworkImageView.image = trackToAdd.lowResArtwork
                    self.recommendationsCollectionView.reloadData()
                }
            }
        }
        
        cell.trackName.text = trackToAdd.name
        cell.artistName.text = trackToAdd.artist
        
        if partyTracksQueue(hasTrack: recommendedTracksList[indexPath.row]) || tracksSelected.contains(recommendedTracksList[indexPath.row]) {
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
            trackToAdd.lowResArtwork = Track.fetchImage(fromURL: trackToAdd.lowResArtworkURL)
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
        if partyTracksQueue(hasTrack: tracksList[indexPath.row]) || tracksSelected.contains(tracksList[indexPath.row]) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
    }
    
    func partyTracksQueue(hasTrack track: Track) -> Bool {
        return Party.tracksQueue.contains(where: { $0.id == track.id })
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = trackTableView.dequeueReusableCell(withIdentifier: "Track", for: indexPath) as! TrackTableViewCell
        
        // Cell Properties
        cell.trackName.text = tracksList[indexPath.row].name
        cell.artistName.text = tracksList[indexPath.row].artist

        if let unwrappedArtwork = tracksList[indexPath.row].lowResArtwork {
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
        if !partyTracksQueue(hasTrack: track) && !tracksSelected.contains(track) {
            tracksSelected.append(track)
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
        tracksSelected.remove(at: tracksSelected.index(where: {$0.id == track.id})!)
    }
}
