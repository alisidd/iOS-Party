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

protocol UpdatePartyDelegate: class {
    func updateEveryonesTableView()
    func showCurrentlyPlayingArtwork()
}

protocol NetworkManagerDelegate: class {
    func id(ofTracks tracks: [Track], withRemoval: Bool) -> [String]
    func remove(trackID: String)
    func connectedDevicesChanged(_ manager : MultipeerManager, connectedDevices: [String])
    func updateStatus(withState state: MCSessionState)
    func setupParty(withParty party: Party)
    func add(tracks: [String], fromPeer peer: MCPeerID)
    func updatePosition(position: TimeInterval)
}

protocol PartyViewControllerInfoDelegate: class {
    var personalQueue: Set<Track> { get }
    func sendTracksToPeers(forTracks: [Track], toRemove: Bool)
    func returnTableHeight() -> CGFloat
    func setTableHeight(withHeight height: CGFloat)
    func layout()
    func amHost() -> Bool
    func getCurrentProgress() -> TimeInterval?
}

class PartyViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, UpdatePartyDelegate, NetworkManagerDelegate, PartyViewControllerInfoDelegate {
    // MARK: - Storyboard Variables
    
    // FIXME: - When adding tracks on host, low res image only loads for first 5 tracks on apple music
    // FIXME: - If nonhost adds first track, host queue doesn't pull down
    
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
        networkManager = MultipeerManager(isHost: false)
        networkManager.delegate = self
        connectionStatus = .connecting
    }
    
    // MARK: - General Variables
    
    lazy var networkManager: MultipeerManager! = {
        let manager = MultipeerManager(isHost: self.isHost)
        manager.delegate = self
        return manager
    }()
    private var latestRequest = [MCPeerID: [String]]()
    
    private var musicPlayer = MusicPlayer()
    var isHost = true
    var personalQueue = Set<Track>()
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
        Party.delegate = self
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
    
    private func initializeMusicPlayer() {
        setTimer()
        musicPlayer.musicService = Party.musicService
        
        if Party.musicService == .spotify {
            musicPlayer.spotifyPlayer?.setTargetBitrate(.low, callback: nil)
        } else {
            musicPlayer.appleMusicPlayer.beginGeneratingPlaybackNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(playNextTrack), name:.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer.appleMusicPlayer)
        }
    }
    
    private func setTimer() {
        let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        if !Party.tracksQueue.isEmpty {
            if Party.musicService == .appleMusic {
                musicPlayer.currentPosition = musicPlayer.appleMusicPlayer.currentPlaybackTime
                networkManager.advertise(position: musicPlayer.currentPosition!)
            }
        }
        print("Running")
    }
    
    // MARK: - UpdatePartyDelegate
    
    func updateEveryonesTableView() {
        // Update own table view
        lyricsAndQueueVC.updateTable()
        updateCurrentlyPlayingTrack()
        
        // Update peers tableview
        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.sendTracksToPeers(forTracks: Party.tracksQueue)
            }
        } else {
            sendTracksToPeers(forTracks: Party.tracksFromPeers)
            Party.tracksFromPeers.removeAll()
            updatePersonalQueue()
        }
    }
    
    private func updateCurrentlyPlayingTrack() {
        DispatchQueue.main.async {
            if !Party.tracksQueue.isEmpty {
                if Party.tracksQueue.count == 1 {
                    self.lyricsAndQueueVC.minimizeTracksTable()
                }
                self.currentlyPlayingTrackName.text = Party.tracksQueue[0].name
                self.currentlyPlayingArtistName.text = Party.tracksQueue[0].artist
                self.updateArtworkForCurrentlyPlaying()
            } else {
                self.hideCurrentlyPlayingArtwork()
            }
        }
    }
    
    private func updateArtworkForCurrentlyPlaying() {
        if let highResArtwork = Party.tracksQueue[0].highResArtwork {
            currentlyPlayingArtwork.image = highResArtwork.addGradient()
        } else {
            let trackToSet = Party.tracksQueue[0]
            DispatchQueue.global(qos: .userInitiated).async {
                if !Party.tracksQueue.isEmpty && trackToSet == Party.tracksQueue[0] {
                    let _ = self.fetchImage(forTrack: trackToSet, setCurrentlyPlaying: true)
                }
            }
        }
    }
    
    private func fetchImage(forTrack track: Track, setCurrentlyPlaying: Bool) -> UIImage? {
        if let url = URL(string: track.highResArtworkURL) {
            do {
                if setCurrentlyPlaying && !Party.tracksQueue.isEmpty && track == Party.tracksQueue[0] {
                    let data = try Data(contentsOf: url)
                    // FIXME: - Crash here when adding a track on nonHost when party is empty on nonHost but 1 track in host
                    // FIXME: - Crash on host here when tracks on host finish
                    print("Setting high res image for \(Party.tracksQueue[0].name)")
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
    
    private func setCurrentlyPlayingImage(withImage image: UIImage?) {
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
    
    private func hideCurrentlyPlayingArtwork() {
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
    func sendTracksToPeers(forTracks tracks: [Track], toRemove: Bool = false) {
        if isHost || (!isHost && !tracks.isEmpty) {
            let tracksIDs = id(ofTracks: tracks, withRemoval: toRemove)
            networkManager.sendTracks()
        }
    }
    
    func id(ofTracks tracks: [Track], withRemoval: Bool = false) -> [String] {
        var result = [String]()
        for track in tracks {
            if withRemoval {
                result.append("R:" + track.id)
            } else if Party.musicService == .spotify {
                result.append("S:" + track.id)
            } else if Party.musicService == .appleMusic {
                result.append("A:" + track.id)
            }
        }
        return result
    }
    
    private func updatePersonalQueue() {
        for track in personalQueue {
            if !Party.tracksQueue.contains(track) {
                personalQueue.remove(at: personalQueue.index(of: track)!)
            }
        }
    }
    
    func add(tracks: [String], fromPeer peer: MCPeerID) {
        func indexInCache(ofTrack track: Track) -> Int? {
            return cache.index(where: { $0.id == track.id })
        }
        
        latestRequest[peer] = tracks
        
        DispatchQueue.global(qos: .userInitiated).async {
            let fetcher: Fetcher = Party.musicService == .spotify ? SpotifyFetcher() : AppleMusicFetcher()
            
            if let requestTracks = self.latestRequest[peer], requestTracks == tracks {
                for trackID in tracks {
                    fetcher.getTrack(forID: trackID)
                    fetcher.dispatchGroup.wait()
                }
                
                if let requestTracksCheck = self.latestRequest[peer], requestTracksCheck == tracks {
                    if Party.tracksQueue.isEmpty && !fetcher.tracksList.isEmpty {
                        self.lyricsAndQueueVC.minimizeTracksTable()
                    }
                    
                    if self.isHost {
                        Party.tracksQueue.append(contentsOf: fetcher.tracksList)
                        if Party.tracksQueue.count == fetcher.tracksList.count {
                            self.musicPlayer.startPlayer(withTracks: Party.tracksQueue)
                        }
                        self.fetchHighResArtwork(forTracks: fetcher.tracksList)
                    } else if fetcher.tracksList != Party.tracksQueue {
                        self.cache = Party.tracksQueue
                        var wholeNewQueue = [Track]()
                        var newTracks = [Track]()
                        
                        for newTrack in fetcher.tracksList {
                            if let index = indexInCache(ofTrack: newTrack) { // TODO: - Use a dictionary for cache
                                wholeNewQueue.append(self.cache[index])
                            } else {
                                wholeNewQueue.append(newTrack)
                                newTracks.append(newTrack)
                            }
                        }
                        
                        Party.tracksQueue = wholeNewQueue
                        self.fetchHighResArtwork(forTracks: newTracks)
                        
                        self.cache.removeAll()
                    }
                }
            }
            
            self.latestRequest.removeValue(forKey: peer)
        }
    }
    
    private func fetchHighResArtwork(forTracks tracks: [Track]) {
        for track in tracks {
            if let index = Party.tracksQueue.index(of: track) {
                print("Fetching high res artwork for \(track.name)")
                Party.tracksQueue[index].highResArtwork = fetchImage(forTrack: track, setCurrentlyPlaying: false)
            }
        }
    }
    
    func remove(trackID: String) {
        let id = trackID.components(separatedBy: ":")[1]
        
        if let i = Party.tracksQueue.index(where: { $0.id == id }) {
            Party.tracksQueue.remove(at: i)
        }
    }
    
    // MARK: - Playback
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // Make sure it's a premium account
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            activateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        if !Party.tracksQueue.isEmpty {
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
    
    @objc private func playNextTrack() {
        if musicPlayer.safeToPlayNextTrack() && !Party.tracksQueue.isEmpty {
            sendTracksToPeers(forTracks: [Party.tracksQueue.removeFirst()], toRemove: true)
            musicPlayer.startPlayer(withTracks: Party.tracksQueue)
        }
    }
    
    @IBAction func skipTrack(_ sender: UIButton) {
        if !Party.tracksQueue.isEmpty {
            sendTracksToPeers(forTracks: [Party.tracksQueue.removeFirst()], toRemove: true)
            musicPlayer.startPlayer(withTracks: Party.tracksQueue)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Lyrics and Queue" {
            if let controller = segue.destination as? HubAndQueuePageViewController {
                controller.partyDelegate = self
            }
        }
    }
    
    @IBAction func unwindToPartyViewController(_ sender: UIStoryboardSegue) {
        if let VC = sender.source as? AddSongViewController {
            DispatchQueue.global(qos: .userInitiated).async {
                Party.tracksFromPeers.append(contentsOf: VC.tracksSelected)
                Party.tracksQueue.append(contentsOf: VC.tracksSelected)
                self.personalQueue = self.personalQueue.union(Set(VC.tracksSelected))
                
                // TODO: go out of editing mode
                if Party.tracksQueue.count > 0 {
                    self.lyricsAndQueueVC.minimizeTracksTable()
                }
                
                if Party.tracksQueue.count == VC.tracksSelected.count && self.isHost {
                    self.musicPlayer.startPlayer(withTracks: Party.tracksQueue)
                }
                
                self.fetchHighResArtwork(forTracks: VC.tracksSelected)
                
                VC.emptyArrays()
            }
        }
    }
    
    // MARK: NetworkManagerDelegate
    
    func connectedDevicesChanged(_ manager: MultipeerManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    func updateStatus(withState state: MCSessionState) {
        connectionStatus = state
    }
    
    func setupParty(withParty party: Party) {
        Party.musicService = type(of: party).musicService
        Party.danceability = type(of: party).danceability
        Party.cookie = type(of: party).cookie
    }
    
    func updatePosition(position: TimeInterval) {
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
    
    func amHost() -> Bool {
        return isHost
    }
    
    func getCurrentProgress() -> TimeInterval? {
        return musicPlayer.currentPosition
    }
}
