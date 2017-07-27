//
//  PartyViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import MediaPlayer
import MultipeerConnectivity

protocol NetworkManagerDelegate: class {
    func connectedDevicesChanged(_ manager : NetworkServiceManager, connectedDevices: [String])
    func updateStatus(with state: MCSessionState)
    func sendPartyInfo(toSession session: MCSession)
    func setupParty(withParty party: Party)
    func addTracks(fromPeer peer: MCPeerID, withTracks tracks: [String])
    func removeTrackFromPeer(withTrack track: String)
    func updatePosition(position: TimeInterval)
}

protocol UpdatePartyDelegate: class {
    func updateEveryonesTableView()
    func showCurrentlyPlayingArtwork()
}

protocol PartyViewControllerInfoDelegate: class {
    func returnTableHeight() -> CGFloat
    func setTableHeight(withHeight height: CGFloat)
    func layout()
    func amHost() -> Bool
    func removeFromOthersQueue(forTrack track: Track)
    func personalQueue(hasTrack track: Track) -> Bool
    func getCurrentProgress() -> TimeInterval?
}

class PartyViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, NetworkManagerDelegate, UpdatePartyDelegate, PartyViewControllerInfoDelegate {
    
    // MARK: - Storyboard Variables
    
    // Currently Playing
    @IBOutlet weak var currentlyPlayingArtwork: UIImageView!
    @IBOutlet weak var currentlyPlayingTrackName: UILabel!
    @IBOutlet weak var currentlyPlayingArtistName: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipTrackButton: UIButton!
    
    // Tracks Queue
    @IBOutlet weak var upNextLabel: UILabel!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    var lyricsAndQueueVC: HubAndQueuePageViewController {
        let vc = childViewControllers.first{ $0 is HubAndQueuePageViewController }
        return vc as! HubAndQueuePageViewController
    }
    
    // Connection Status
    @IBOutlet weak var connectionStatusLabel: UILabel!
    @IBOutlet weak var reconnectButton: UIButton!
    
    @IBAction func reconnectToParty(_ sender: UIButton) {
        networkManager = nil
        assert(!self.isHost, "Wasn't supposed to happen!")
        networkManager = NetworkServiceManager(isHost: false)
        networkManager.delegate = self
        connectionStatus = .connecting
    }
    
    // MARK: - General Variables
    
    lazy var networkManager: NetworkServiceManager! = {
        let manager = NetworkServiceManager(isHost: self.isHost)
        manager.delegate = self
        return manager
    }()
    private let APIManager = RestApiManager()
    
    var party = Party()
    private var musicPlayer = MusicPlayer()
    var isHost = true
    private var personalQueue = [Track]()
    private var cache = [Track]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        adjustViews()
        
        if isHost {
            initializeMusicPlayer()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    // MARK: - General Functions
    
    private func setDelegates() {
        party.delegate = self
        musicPlayer.spotifyPlayer?.delegate = self
        musicPlayer.spotifyPlayer?.playbackDelegate = self
    }
    
    private func adjustViews() {
        hideCurrentlyPlayingArtwork()
        if !isHost {
            playPauseButton.isHidden = true
            skipTrackButton.isHidden = true
            connectionStatus = .notConnected
        }
    }
    
    func initializeMusicPlayer() {
        setTimer()
        musicPlayer.musicService = party.musicService
        
        if party.musicService == .spotify {
            SpotifyAuthorizationManager.authorizeSpotifyAccess()
            musicPlayer.spotifyPlayer?.setTargetBitrate(.low, callback: nil)
        } else {
            musicPlayer.appleMusicPlayer.beginGeneratingPlaybackNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(playNextTrack), name:.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer.appleMusicPlayer)
        }
    }
    
    func setTimer() {
        let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    func updateProgress() {
        if !party.tracksQueue.isEmpty {
            if party.musicService == .appleMusic {
                musicPlayer.currentPosition = musicPlayer.appleMusicPlayer.currentPlaybackTime
                networkManager.advertise(forPosition: musicPlayer.currentPosition!)
            }
        }
        print("Running")
    }
    
    // MARK: - Modify Queue and Views From Peers
    
    internal func updateEveryonesTableView() {
        // Update own table view
        lyricsAndQueueVC.updateTable()
        
        updateCurrentlyPlayingTrack()
        
        // Update peers tableview
        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.sendTracksToPeers(forTracks: self.party.tracksQueue)
            }
        } else {
            sendTracksToPeers(forTracks: party.tracksFromPeers)
            party.tracksFromPeers.removeAll()
            updatePersonalQueue()
        }
    }
    
    func updateCurrentlyPlayingTrack() {
        DispatchQueue.main.async {
            if !self.party.tracksQueue.isEmpty {
                if self.party.tracksQueue.count == 1 {
                    self.lyricsAndQueueVC.minimizeTracksTable()
                }
                self.currentlyPlayingTrackName.text = self.party.tracksQueue[0].name
                self.currentlyPlayingArtistName.text = self.party.tracksQueue[0].artist
                self.updateArtworkForCurrentlyPlaying()
            } else {
                self.hideCurrentlyPlayingArtwork()
            }
        }
    }
    
    func updateArtworkForCurrentlyPlaying() {
        if let highResArtwork = party.tracksQueue[0].highResArtwork {
            currentlyPlayingArtwork.image = highResArtwork.addGradient()
        } else {
            let trackToSet = party.tracksQueue[0]
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.party.tracksQueue.isEmpty && trackToSet == self.party.tracksQueue[0] {
                    let _ = self.fetchImage(forTrack: trackToSet, setCurrentlyPlaying: true)
                }
            }
        }
    }
    
    private func fetchImage(forTrack track: Track, setCurrentlyPlaying: Bool) -> UIImage? {
        if let url = URL(string: track.highResArtworkURL) {
            do {
                if setCurrentlyPlaying && !party.tracksQueue.isEmpty && track == party.tracksQueue[0] {
                    let data = try Data(contentsOf: url)
                    // FIXME: - Crash here when adding a track on nonHost when party is empty on nonHost but 1 track in host
                    print("Setting high res image for \(party.tracksQueue[0].name)")
                    setCurrentlyPlayingImage(withImage: UIImage(data: data))
                } else if !setCurrentlyPlaying {
                    let data = try Data(contentsOf: url)
                    return UIImage(data: data)
                }
                
            } catch {
                print("Error trying to get high resolution artwork")
                return nil
            }
        }
        return nil
    }
    
    func setCurrentlyPlayingImage(withImage image: UIImage?) {
        if let unwrappedImage = image {
            DispatchQueue.main.async {
                self.currentlyPlayingArtwork.image = unwrappedImage.addGradient()
            }
        }
    }
    
    func showCurrentlyPlayingArtwork() {
        DispatchQueue.main.async {
            self.currentlyPlayingArtwork.isHidden = false
            self.currentlyPlayingTrackName.isHidden = false
            self.currentlyPlayingArtistName.isHidden = false
            if self.isHost {
                self.playPauseButton.isHidden = false
                self.skipTrackButton.isHidden = false
            }
        }
    }
    
    func hideCurrentlyPlayingArtwork() {
        DispatchQueue.main.async {
            self.currentlyPlayingArtwork.isHidden = true
            self.currentlyPlayingArtwork.image = nil
            self.currentlyPlayingTrackName.isHidden = true
            self.currentlyPlayingArtistName.isHidden = true
            self.playPauseButton.isHidden = true
            self.skipTrackButton.isHidden = true
            self.lyricsAndQueueVC.expandTracksTable()
        }
    }
    
    // Handles addition and removal of tracks
    private func sendTracksToPeers(forTracks tracks: [Track]) {
        let tracksIDString = id(ofTracks: tracks)
        if isHost || (!isHost && !tracks.isEmpty) {
            networkManager.sendTracks(tracksIDString)
        }
    }
    
    func id(ofTracks tracks: [Track]) -> [String] {
        var result = [String]()
        for track in tracks {
            if party.musicService == .spotify {
                result.append(track.id)
            } else {
                result.append(track.id + "-" + track.artist)
            }
        }
        return result
    }
    
    func updatePersonalQueue() {
        for track in personalQueue {
            if !party.tracksQueue.contains(track) {
                personalQueue.remove(at: personalQueue.index(of: track)!)
            }
        }
    }
    
    func addTracks(fromPeer peer: MCPeerID, withTracks tracks: [String]) {
        APIManager.latestRequest[peer] = tracks
        
        DispatchQueue.global(qos: .userInteractive).async {
            let API = RestApiManager()
            
            if let requestTracks = self.APIManager.latestRequest[peer], requestTracks == tracks {
                
                for trackID in tracks {
                    if self.isASpotifyTrack(forTrackID: trackID) {
                        API.makeHTTPRequestToSpotifyForSingleTrack(forID: trackID)
                    } else {
                        API.makeHTTPRequestToAppleForSingleTrack(forID: trackID)
                    }
                    
                    API.dispatchGroup.wait()
                }
                
                if let requestTracksCheck = self.APIManager.latestRequest[peer], requestTracksCheck == tracks {
                
                    if self.isHost {
                        self.party.tracksQueue.append(contentsOf: API.tracksList)
                        if self.party.tracksQueue.count == API.tracksList.count {
                            self.musicPlayer.modifyQueue(withTracks: self.party.tracksQueue)
                        }
                        self.fetchHighResArtwork(forTracks: API.tracksList)
                    } else {
                        if self.party.tracksQueue.isEmpty {
                            if !API.tracksList.isEmpty {
                                self.lyricsAndQueueVC.minimizeTracksTable()
                            }
                        }
                        
                        if API.tracksList != self.party.tracksQueue {
                            self.cache = self.party.tracksQueue
                            var wholeNewQueue = [Track]()
                            var newTracks = [Track]()
                            
                            for newTrack in API.tracksList {
                                if let index = self.indexInCache(ofTrack: newTrack) {
                                    wholeNewQueue.append(self.cache[index])
                                } else {
                                    wholeNewQueue.append(newTrack)
                                    newTracks.append(newTrack)
                                }
                            }
                            
                            self.party.tracksQueue = wholeNewQueue
                            self.updateCurrentlyPlayingTrack()
                            self.lyricsAndQueueVC.updateTable()
                            
                            self.fetchHighResArtwork(forTracks: newTracks)
                            
                            self.cache.removeAll()
                        }
                    }
                }
            }
            
            self.APIManager.latestRequest.removeValue(forKey: peer)
        }
    }
    
    func isASpotifyTrack(forTrackID id: String) -> Bool {
        let ids = id.components(separatedBy: "-")
        return ids.count == 1
    }
    
    func indexInCache(ofTrack track: Track) -> Int? {
        for i in 0..<cache.count {
            if cache[i].id == track.id {
                return i
            }
        }
        return nil
    }
    
    func fetchHighResArtwork(forTracks tracks: [Track]) {
        for track in tracks {
            if let index = party.tracksQueue.index(of: track) {
                print("Fetching high res artwork for \(track.name)")
                party.tracksQueue[index].highResArtwork = fetchImage(forTrack: track, setCurrentlyPlaying: false)
            }
        }
    }
    
    func removeFromOthersQueue(forTrack track: Track) {
        track.id = "R:" + track.id
        sendTracksToPeers(forTracks: [track])
    }
    
    func removeTrackFromPeer(withTrack trackID: String) {
        let id = trackID.components(separatedBy: ":")[1]
        
        for i in 0..<party.tracksQueue.count {
            if id == party.tracksQueue[i].id {
                party.tracksQueue.remove(at: i)
                break
            }
        }
    }
    
    // MARK: - Playback
    
    internal func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // Make sure it's a premium account
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            activateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        if !party.tracksQueue.isEmpty {
            musicPlayer.currentPosition = position
        }
    }
    
    private func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        playNextTrack()
    }
    
    // MARK: - Storyboard Functions
    
    @IBAction func playPauseChange(_ sender: UIButton) {
        if musicPlayer.isPaused() {
            UIView.animate(withDuration: 0.1, animations: {
                sender.alpha = 0.0
            }, completion: { (finished) in
                sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                UIView.animate(withDuration: 0.25) {
                    sender.alpha = 1
                }
            })
            musicPlayer.playTrack()
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                sender.alpha = 0.0
            }, completion: { (finished) in
                sender.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                UIView.animate(withDuration: 0.25) {
                    sender.alpha = 1
                }
            })
            musicPlayer.pauseTrack()
        }
    }
    
    // MARK: - Callbacks
    
    @objc func playNextTrack() {
        if musicPlayer.safeToPlayNextTrack() && !party.tracksQueue.isEmpty {
            removeFromOthersQueue(forTrack: party.tracksQueue[0])
            print("Removing \(party.tracksQueue.removeFirst().name)")
            musicPlayer.modifyQueue(withTracks: party.tracksQueue)
            
            //TODO: - Isn't this automatically called by removing the top track?
            updateEveryonesTableView()
        }
    }
    
    @IBAction func skipTrack(_ sender: UIButton) {
        if !party.tracksQueue.isEmpty {
            removeFromOthersQueue(forTrack: party.tracksQueue[0])
            print("Removing \(party.tracksQueue.removeFirst().name)")
            musicPlayer.modifyQueue(withTracks: party.tracksQueue)
            
            updateEveryonesTableView()
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Lyrics and Queue" {
            if let controller = segue.destination as? HubAndQueuePageViewController {
                controller.party = party
                controller.partyDelegate = self
            }
        }
    }
    
    @IBAction func unwindToPartyViewController(_ sender: UIStoryboardSegue) {
        if let VC = sender.source as? AddSongViewController {
            DispatchQueue.global(qos: .userInitiated).async {
                self.party.tracksFromPeers.append(contentsOf: VC.tracksQueue)
                self.party.tracksQueue.append(contentsOf: VC.tracksQueue)
                self.personalQueue.append(contentsOf: VC.tracksQueue)
                
                if self.party.tracksQueue.count > 0 {
                    self.lyricsAndQueueVC.minimizeTracksTable()
                }
                
                if self.party.tracksQueue.count == VC.tracksQueue.count && self.isHost {
                    self.musicPlayer.modifyQueue(withTracks: self.party.tracksQueue)
                }
                
                self.fetchHighResArtwork(forTracks: VC.tracksQueue)
                
                VC.emptyArrays()
            }
        }
    }
    
    // MARK: NetworkManagerDelegate
    
    internal func connectedDevicesChanged(_ manager: NetworkServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    func updateStatus(with state: MCSessionState) {
        connectionStatus = state
    }
    
    internal func amHost() -> Bool {
        return isHost
    }
    
    internal func sendPartyInfo(toSession session: MCSession) {
        if isHost {
            networkManager.sendPartyInfo(forParty: party, toSession: session)
        }
    }
    
    internal func setupParty(withParty party: Party) {
        print("Setting up party using party info received")
        self.party.musicService = party.musicService
        self.party.danceability = party.danceability
    }
    
    internal func updatePosition(position: TimeInterval) {
        musicPlayer.currentPosition = position
    }
    
    // MARK: PartyViewControllerInfoDelegate
    
    func returnTableHeight() -> CGFloat {
        return tableHeightConstraint.constant
    }
    
    func setTableHeight(withHeight height: CGFloat) {
        tableHeightConstraint.constant = height
    }
    
    func layout() {
        view.layoutIfNeeded()
    }
    
    func personalQueue(hasTrack track: Track) -> Bool {
        for trackinQueue in personalQueue {
            if track.id == trackinQueue.id {
                return true
            }
        }
        return false
    }
    
    func getCurrentProgress() -> TimeInterval? {
        return musicPlayer.currentPosition
    }
}
