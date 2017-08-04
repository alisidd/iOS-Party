//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift

class AddSongViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var searchTracksField: UITextField!
    @IBOutlet weak var tracksCounter: BadgeSwift!
    
    @IBOutlet weak var trackTableView: UITableView!
    
    // FIXME: - Done lags when adding tracks
    
    // MARK: - General Variables
    
    private var tracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.trackTableView.reloadData()
                self.indicator.stopAnimating()
                self.indicator.hidesWhenStopped = true
                self.fetchArtworkForRestOfTracks()
            }
        }
    }
    var tracksSelected = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.tracksCounter.isHidden = self.tracksSelected.isEmpty
                self.tracksCounter.text = String(self.tracksSelected.count)
            }
        }
    }
    private var fetcher: Fetcher!
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
    
    private func setDelegates() {
        searchTracksField.delegate = self
        trackTableView.delegate    = self
        trackTableView.dataSource  = self
    }
    
    private func initializeActivityIndicator() {
        indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.whiteLarge
        indicator.center = view.center
        view.addSubview(indicator)
    }
    
    private func adjustViews() {
        trackTableView.backgroundColor = .clear
        trackTableView.tableFooterView = UIView()
        
        navigationItem.hidesBackButton = true
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchTracksField.resignFirstResponder()
        if !searchTracksField.text!.isEmpty {
            fetcher = Party.musicService == .spotify ? SpotifyFetcher() : AppleMusicFetcher()
            fetchResults(forTerm: searchSongsField.text!)
        }
        return true
    }
    
    private func fetchResults(forTerm term: String) {
        indicator.startAnimating()
        showTableView()
        
        fetcher.searchCatalog(forTerm: term) { [weak self] in
            self?.populateTracksList()
            self?.scrollUp()
        }
    }
    
    private func showTableView() {
        trackTableView.isHidden = false
    }
    
    private func scrollUp() {
        DispatchQueue.main.async {
            if !self.tracksList.isEmpty {
                self.trackTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
            }
        }
    }
    
    private func populateTracksList() {
        tracksList = fetcher.tracksList
        DispatchQueue.main.async {
            if self.tracksList.isEmpty {
                self.displayNoTracksLabel(withText: "No Tracks Found")
            } else {
                self.removeNoTracksFoundLabel()
            }
        }
    }
    
    private func displayNoTracksLabel(withText text: String) {
        customizeLabel(withText: text)
        view.addSubview(noTracksFoundLabel)
    }
    
    private func customizeLabel(withText text: String) {
        noTracksFoundLabel.text = text
        noTracksFoundLabel.textColor = .white
        noTracksFoundLabel.textAlignment = .center
        
        noTracksFoundLabel.center = view.center
        noTracksFoundLabel.lineBreakMode = .byWordWrapping
        noTracksFoundLabel.numberOfLines = 0
    }
    
    private func removeNoTracksFoundLabel() {
        noTracksFoundLabel.removeFromSuperview()
    }
    
    private func fetchArtworkForRestOfTracks() {
        let tracksCaptured = tracksList
        for track in tracksList where tracksList == tracksCaptured && track.lowResArtwork == nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                Track.fetchImage(fromURL: track.lowResArtworkURL) { (image) in
                    track.lowResArtwork = image
                    self?.trackTableView.reloadData()
                }
            }
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
        cell.artworkImageView.image = tracksList[indexPath.row].lowResArtwork
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = trackTableView.cellForRow(at: indexPath)!
        
        addToQueue(track: tracksList[indexPath.row])
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .checkmark
        }
    }
    
    private func addToQueue(track: Track) {
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
    
    private func removeFromQueue(track: Track) {
        tracksSelected.remove(at: tracksSelected.index(where: {$0.id == track.id})!)
    }
}
