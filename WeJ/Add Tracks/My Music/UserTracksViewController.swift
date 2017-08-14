//
//  UserTracksViewController.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/12/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift
import NVActivityIndicatorView

class UserTracksViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badge: BadgeSwift!
    @IBOutlet weak var tracksTableView: UITableView!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    
    var fetcher: Fetcher!
    var musicService: MusicService!
    var playlistName: String!
    var playlistType: PlaylistType!
    
    var intermediateTracksList: [Track]!
    var libraryTracksList = [Track]() {
        didSet {
            DispatchQueue.main.async {
                self.populateUserTracksDict()
                self.tracksTableView.reloadData()
                self.activityIndicator.stopAnimating()
                self.fetchArtworkForRestOfTracks()
            }
        }
    }
    var libraryTracksDict = [String: [Track]]()
    var orderedLibraryTracksDictKeys: [String] {
        return libraryTracksDict.keys.sorted()
    }
    
    var userTracksSelected: [Track] {
        get {
            if let controller = tabBarController as? AddTracksTabBarController {
                return controller.libraryTracksSelected
            } else {
                return []
            }
        }
        set {
            (tabBarController! as! AddTracksTabBarController).libraryTracksSelected = newValue
        }
    }
    
    func setBadge(to count: Int) {
        badge.isHidden = count == 0
        badge.text = String(count)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeVariables()
        adjustViews()
        setDelegates()
        adjustTableView()
        
        if case .some(.all) = playlistType {
            populateAllTracks()
        } else {
            populateSpecificTracks()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeBadge()
    }
    
    private func initializeBadge() {
        let controller = tabBarController! as! AddTracksTabBarController
        setBadge(to: controller.tracksSelected.count + controller.libraryTracksSelected.count)
    }
    
    private func initializeVariables() {
        fetcher = (musicService == .spotify) ? SpotifyFetcher() : AppleMusicFetcher()
    }
    
    private func adjustViews() {
        titleLabel.text = playlistName
    }
    
    private func setDelegates() {
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
    }
    
    private func adjustTableView() {
        tracksTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        
        tracksTableView.sectionIndexColor = .gray
        tracksTableView.sectionIndexBackgroundColor = AppConstants.black
    }
    
    private func populateSpecificTracks() {
        switch playlistType {
        case .some(.albums): populateAlbumTracks()
        case .some(.artists): populateArtistTracks()
        case .some(.playlists): populatePlaylistTracks()
        default: break
        }
    }
    
    private func populateAlbumTracks() {
        libraryTracksList = intermediateTracksList
    }
    
    private func populateArtistTracks() {
        if musicService == .appleMusic {
            libraryTracksList = intermediateTracksList
        }
    }
    
    private func populatePlaylistTracks() {
        if musicService == .spotify {
            populateSpotifyPlaylistTracks()
        } else {
            libraryTracksList = intermediateTracksList
        }
    }
    
    private func populateSpotifyPlaylistTracks() {
        let spotifyPlaylistFetcher = SpotifyFetcher()
        activityIndicator.startAnimating()

        if !intermediateTracksList.isEmpty {
            spotifyPlaylistFetcher.getUserPlaylistTracks(forOwnerID: intermediateTracksList[0].id, withPlaylistID: intermediateTracksList[0].name) { [weak self] in
                guard self != nil else { return }
                self!.libraryTracksList = spotifyPlaylistFetcher.tracksList
            }
        }
    }
    
    private func populateAllTracks() {
        activityIndicator.startAnimating()
        fetcher.getUserTracks { [weak self] in
            guard self != nil else { return }
            self?.libraryTracksList = self!.fetcher.tracksList
        }
    }
    
    private func populateUserTracksDict() {
        for track in libraryTracksList {
            let key = String(track.name.characters.first ?? "#")
            
            if libraryTracksDict[key] != nil {
                libraryTracksDict[key]!.append(track)
            } else {
                libraryTracksDict[key] = [track]
            }
        }
    }
    
    private func fetchArtworkForRestOfTracks() {
        guard musicService == .spotify else { return }
        
        let tracksCaptured = libraryTracksList
        for track in libraryTracksList where libraryTracksList == tracksCaptured && track.lowResArtwork == nil {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                Track.fetchImage(fromURL: track.lowResArtworkURL) { (image) in
                    track.lowResArtwork = image
                    self?.tracksTableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return libraryTracksDict.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return libraryTracksDict[orderedLibraryTracksDictKeys[section]]!.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        
        let section = orderedLibraryTracksDictKeys[indexPath.section]
        let track = libraryTracksDict[section]![indexPath.row]
        if userTracksSelected.contains(where: { $0.id == track.id }) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Track", for: indexPath) as! TrackTableViewCell
        
        let section = orderedLibraryTracksDictKeys[indexPath.section]
        let track = libraryTracksDict[section]![indexPath.row]
        
        // Cell Properties
        cell.trackName.text = track.name
        cell.artistName.text = track.artist
        cell.artworkImageView.image = track.lowResArtwork
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        let section = orderedLibraryTracksDictKeys[indexPath.section]
        let track = libraryTracksDict[section]![indexPath.row]
        
        addToQueue(track: track)
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .checkmark
        }
    }
    
    private func addToQueue(track: Track) {
        if !userTracksSelected.contains(track) {
            userTracksSelected.append(track)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = AppConstants.darkerBlack
        
        let label = UILabel(frame: CGRect(x: 30, y: view.center.y + 13, width: 40, height: 15))
        label.text = orderedLibraryTracksDictKeys[section]
        label.font = UIFont(name: "AvenirNext-Bold", size: 20)
        label.textColor = .white
        
        view.addSubview(label)
        
        return view
    }
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return orderedLibraryTracksDictKeys
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        let section = orderedLibraryTracksDictKeys[indexPath.section]
        let track = libraryTracksDict[section]![indexPath.row]
        
        removeFromQueue(track: track)
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .none
        }
    }
    
    private func removeFromQueue(track: Track) {
        if let index = userTracksSelected.index(where: {$0.id == track.id}) {
            userTracksSelected.remove(at: index)
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func goBack() {
        navigationController?.popViewController(animated: true)
    }
    

}
