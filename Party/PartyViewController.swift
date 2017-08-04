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
    var lyricsAndQueueVC: HubAndQueuePageViewController { get }
    func updateEveryonesTableView()
    func showCurrentlyPlayingArtwork()
}

protocol NetworkManagerDelegate: class {
    func connectedDevicesChanged(_ manager : MultipeerManager, connectedDevices: [String])
    func updateStatus(withState state: MCSessionState)
    func setup(withParty party: Party)
    func add(tracksReceived: [Track])
    func remove(track: Track)
    func update(usingPosition position: TimeInterval)
}

protocol PartyViewControllerInfoDelegate: class {
    var isHost: Bool { get }
    var personalQueue: Set<Track> { get }
    func sendTracksToPeers(forTracks: [Track], toRemove: Bool)
    func returnTableHeight() -> CGFloat
    func setTable(withHeight height: CGFloat)
    func layout()
    func getCurrentProgress() -> TimeInterval?
}

class PartyViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, UpdatePartyDelegate, NetworkManagerDelegate, PartyViewControllerInfoDelegate {
    // MARK: - Storyboard Variables
    
    // FIXME: - Handle background tasks properly (stop when music is stopped)
    // FIXME: - Remove memory leaks when fetching artwork
    // TODO: - Improve interface for reconnecting to parties
    
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
    
    private var musicPlayer = MusicPlayer()
    var isHost = true
    var personalQueue = Set<Track>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    deinit {
        Party.reset()
    }
    
    // MARK: - General Functions
    
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
        
        if Party.musicService == .spotify {
            setSpotifyDelegates()
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
    
    private func setSpotifyDelegates() {
        musicPlayer.spotifyPlayer?.delegate = self
        musicPlayer.spotifyPlayer?.playbackDelegate = self
    }
    
    // MARK: - UpdatePartyDelegate
    
    func updateEveryonesTableView() {
        // Update own table view
        lyricsAndQueueVC.updateTable()
        fetchArtwork(forHighRes: false)
        fetchArtwork(forHighRes: true)
        updateCurrentlyPlayingTrack()
        
        // Update peers tableview
        if isHost {
            sendTracksToPeers(forTracks: Party.tracksQueue)
        } else {
            sendTracksToPeers(forTracks: Party.tracksFromMyself)
            Party.tracksFromMyself.removeAll()
            updatePersonalQueue()
        }
    }
    
    private func fetchArtwork(forHighRes: Bool) {
        let latestTracks = Party.tracksQueue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            for track in Party.tracksQueue where latestTracks == Party.tracksQueue {
                if forHighRes && track.highResArtwork == nil {
                    self?.fetchHighResArtwork(forTrack: track)
                } else if !forHighRes && track.lowResArtwork == nil {
                    self?.fetchLowResArtwork(forTrack: track)
                }
            }
        }
    }
    
    private func fetchHighResArtwork(forTrack track: Track) {
        Track.fetchImage(fromURL: track.highResArtworkURL) { [weak self] (image) in
            track.highResArtwork = image
            if !Party.tracksQueue.isEmpty && track == Party.tracksQueue[0] {
                self?.currentlyPlayingArtwork.image = track.highResArtwork?.addGradient()
            }
        }
    }

    private func fetchLowResArtwork(forTrack track: Track) {
        Track.fetchImage(fromURL: track.lowResArtworkURL) { [weak self] (image) in
            track.lowResArtwork = image
            self?.lyricsAndQueueVC.updateTable()
        }
    }
    
    private func updateCurrentlyPlayingTrack() {
        DispatchQueue.main.async {
            if !Party.tracksQueue.isEmpty {
                self.currentlyPlayingArtwork.image = Party.tracksQueue[0].highResArtwork?.addGradient()
                self.currentlyPlayingTrackName.text = Party.tracksQueue[0].name
                self.currentlyPlayingArtistName.text = Party.tracksQueue[0].artist
            } else {
                self.hideCurrentlyPlayingArtwork()
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
            if toRemove {
                let tracks = modifyTracksToRemove(usingTracks: tracks)
                networkManager.send(tracks: tracks)
            } else {
                networkManager.send(tracks: tracks)
            }
        }
    }
    
    private func modifyTracksToRemove(usingTracks tracks: [Track]) -> [Track] {
        for track in tracks {
            track.id = "R:" + track.id
        }
        return tracks
    }
    
    private func updatePersonalQueue() {
        for track in personalQueue where !Party.tracksQueue.contains(where: { $0.id == track.id }) {
            personalQueue.remove(at: personalQueue.index(of: track)!)
        }
    }
    
    func add(tracksReceived: [Track]) {
        if isHost {
            Party.tracksQueue.append(contentsOf: tracksReceived)
            if Party.tracksQueue.count == tracksReceived.count {
                musicPlayer.startPlayer(withTracks: Party.tracksQueue)
            }
        } else {
            Party.tracksQueue = tracksReceived
        }
    }
    
    func remove(track: Track) {
        let id = track.id.components(separatedBy: ":")[1]
        
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
            Party.tracksFromMyself.append(contentsOf: VC.tracksSelected)
            personalQueue = personalQueue.union(Set(VC.tracksSelected))
            Party.tracksQueue.append(contentsOf: VC.tracksSelected)
            
            if Party.tracksQueue.count == VC.tracksSelected.count && isHost {
                musicPlayer.startPlayer(withTracks: Party.tracksQueue)
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
    
    func setup(withParty party: Party) {
        Party.musicService = type(of: party).musicService
        Party.danceability = type(of: party).danceability
        Party.cookie = type(of: party).cookie
    }
    
    func update(usingPosition position: TimeInterval) {
        musicPlayer.currentPosition = position
    }
    
    // MARK: PartyViewControllerInfoDelegate
    
    func returnTableHeight() -> CGFloat {
        return tableHeightConstraint.constant
    }
    
    func setTable(withHeight height: CGFloat) {
        tableHeightConstraint.constant = height
    }
    
    func layout() {
        view.layoutIfNeeded()
    }
    
    func getCurrentProgress() -> TimeInterval? {
        return musicPlayer.currentPosition
    }
}
