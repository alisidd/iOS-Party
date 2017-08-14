//
//  PartyViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import MediaPlayer
import MultipeerConnectivity

protocol UpdatePartyDelegate: class {
    var hubAndQueueVC: HubAndQueuePageViewController? { get }
    func updateEveryonesTableView()
    func showCurrentlyPlayingArtwork()
}

protocol NetworkManagerDelegate: class {
    func resetManager()
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
}

class PartyViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, UpdatePartyDelegate, NetworkManagerDelegate, PartyViewControllerInfoDelegate {
    
    // MARK: - Storyboard Variables
    
    // Currently Playing
    @IBOutlet weak var currentlyPlayingArtwork: UIImageView!
    @IBOutlet weak var currentlyPlayingTrackName: UILabel!
    @IBOutlet weak var currentlyPlayingArtistName: UILabel!
    @IBOutlet weak var currentlyPlayingStackViewConstraint: NSLayoutConstraint!

    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var skipTrackButton: UIButton!
    
    // Tracks Queue
    @IBOutlet weak var upNextLabel: UILabel!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    var hubAndQueueVC: HubAndQueuePageViewController? {
        return childViewControllers.first{ $0 is HubAndQueuePageViewController } as? HubAndQueuePageViewController
    }
    
    // Connection Status
    @IBOutlet weak var alertViewConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusIndicatorView: UIView!
    @IBOutlet weak var alertLabel: UILabel!
    @IBOutlet weak var reconnectButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    
    var connectionStatus: MCSessionState = .notConnected {
        willSet {
            showConnectionRelatedViewsOnAlert()
            alertLabel.text = newValue.stringValue()
            displayAlert()
            
            if newValue == .connected {
                changeStatusIndicatorView(toColor: AppConstants.green)
                hideAlert { [weak self] _ in self?.showFailedTracks() }
            } else if newValue == .connecting {
                changeStatusIndicatorView(toColor: AppConstants.orange)
            } else {
                changeStatusIndicatorView(toColor: AppConstants.red)
                hubAndQueueVC?.hideAddButton()
            }
        }
    }
    
    @IBAction func reconnectToParty() {
        resetManager()
    }
    
    // MARK: - General Variables
    
    lazy var networkManager: MultipeerManager? = { [unowned self] in
        let manager = MultipeerManager(isHost: self.isHost)
        manager.delegate = self
        return manager
    }()
    var fetcher: Fetcher!
    
    private var musicPlayer = MusicPlayer()
    var isHost = true
    var personalQueue = Set<Track>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adjustViews()
        
        if isHost {
            initializeMusicPlayer()
        } else {
            initializeStatusIndicatorView()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    deinit {
        Party.reset()
        
        if isHost {
            musicPlayer.stopPlayer()
        }
    }
    
    // MARK: - General Functions
    
    private func adjustViews() {
        hideCurrentlyPlayingArtwork()
        if !isHost {
            currentlyPlayingStackViewConstraint.constant -= 55
            playPauseButton.isHidden = true
            skipTrackButton.isHidden = true
            updateStatus(withState: .notConnected)
        }
    }
    
    private func initializeMusicPlayer() {
        setTimer()
        initializeCommandCenter()
        setupControlEvents()
        
        if Party.musicService == .spotify {
            setSpotifyDelegates()
            musicPlayer.spotifyPlayer?.setTargetBitrate(.low, callback: nil)
        } else {
            musicPlayer.appleMusicPlayer.beginGeneratingPlaybackNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(playNextTrack), name:.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer.appleMusicPlayer)
        }
    }
    
    private func initializeStatusIndicatorView() {
        statusIndicatorView.layer.cornerRadius = statusIndicatorView.frame.size.width / 2
        statusIndicatorView.clipsToBounds = true
    }
    
    private func setTimer() {
        let _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        if !Party.tracksQueue.isEmpty {
            if Party.musicService == .appleMusic {
                MusicPlayer.currentPosition = musicPlayer.appleMusicPlayer.currentPlaybackTime
            }
            if let position = MusicPlayer.currentPosition {
                networkManager?.advertise(position: position)
            }
            if musicPlayer.isPaused() && Party.musicService == .appleMusic {
                BackgroundTask.stopBackgroundTask()
            } else if Party.musicService == .appleMusic {
                BackgroundTask.startBackgroundTask()
            }
        }
        networkManager?.advertise()
    }
    
    private func initializeCommandCenter() {
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().nextTrackCommand.isEnabled = true
    }
    
    private func setupControlEvents() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.musicPlayer.pauseTrack()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.musicPlayer.playTrack()
            return .success
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.skipTrack()
            return .success
        }
    }
    
    private func setSpotifyDelegates() {
        musicPlayer.spotifyPlayer?.playbackDelegate = self
    }
    
    // MARK: - UpdatePartyDelegate
    
    func updateEveryonesTableView() {
        // Update own table view
        hubAndQueueVC?.updateTable()
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
            for (i, track) in Party.tracksQueue.enumerated() where latestTracks == Party.tracksQueue {
                if forHighRes && track.highResArtwork == nil && i < 15 {
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
                self?.updateControlCenter()
            }
        }
    }

    private func fetchLowResArtwork(forTrack track: Track) {
        Track.fetchImage(fromURL: track.lowResArtworkURL) { [weak self] (image) in
            track.lowResArtwork = image
            self?.hubAndQueueVC?.updateTable()
        }
    }
    
    private func updateCurrentlyPlayingTrack() {
        DispatchQueue.main.async {
            if !Party.tracksQueue.isEmpty {
                self.currentlyPlayingArtwork.image = Party.tracksQueue[0].highResArtwork?.addGradient()
                self.currentlyPlayingTrackName.text = Party.tracksQueue[0].name
                self.currentlyPlayingArtistName.text = Party.tracksQueue[0].artist
                self.updateControlCenter()
            } else {
                self.hideCurrentlyPlayingArtwork()
            }
        }
    }
    
    private func updateControlCenter() {
        if let image = Party.tracksQueue[0].highResArtwork {
            let image = MPMediaItemArtwork.init(boundsSize: image.size) { _ in return image }
            let trackInfo: [String: Any] = [MPMediaItemPropertyTitle: Party.tracksQueue[0].name,
                                             MPMediaItemPropertyArtist: Party.tracksQueue[0].artist,
                                             MPMediaItemPropertyArtwork: image]
            MPNowPlayingInfoCenter.default().nowPlayingInfo = trackInfo
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
            self.hubAndQueueVC?.expandTracksTable()
        }
    }
    
    // Handles addition and removal of tracks
    func sendTracksToPeers(forTracks tracks: [Track], toRemove isRemoval: Bool = false) {
        if isHost || (!isHost && !tracks.isEmpty) {
            if isRemoval {
                let tracks = modifyTracksToRemove(usingTracks: tracks)
                networkManager?.send(tracks: tracks, toRemove: isRemoval)
            } else {
                networkManager?.send(tracks: tracks, toRemove: isRemoval)
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
                musicPlayer.startPlayer()
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
    
    // MARK: - Spotify Playback
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            activateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        if !Party.tracksQueue.isEmpty {
            MusicPlayer.currentPosition = position
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
            }, completion: { _ in
                sender.setImage(#imageLiteral(resourceName: "pauseIcon"), for: .normal)
                sender.setImage(#imageLiteral(resourceName: "pauseIconHighlighted"), for: .highlighted)
                UIView.animate(withDuration: 0.25) {
                    sender.alpha = 1
                }
            })
            musicPlayer.playTrack()
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                sender.alpha = 0.0
            }, completion: { _ in
                sender.setImage(#imageLiteral(resourceName: "playIcon"), for: .normal)
                sender.setImage(#imageLiteral(resourceName: "playIconHighlighted"), for: .highlighted)
                UIView.animate(withDuration: 0.25) {
                    sender.alpha = 1
                }
            })
            musicPlayer.pauseTrack()
        }
    }
    
    @IBAction func skipTrack() {
        if !Party.tracksQueue.isEmpty {
            sendTracksToPeers(forTracks: [Party.tracksQueue.removeFirst()], toRemove: true)
            musicPlayer.startPlayer()
        }
    }
    
    // MARK: - Callbacks
    
    @objc private func playNextTrack() {
        if musicPlayer.safeToPlayNextTrack() && !Party.tracksQueue.isEmpty {
            sendTracksToPeers(forTracks: [Party.tracksQueue.removeFirst()], toRemove: true)
            musicPlayer.startPlayer()
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
        if let controller = sender.source.tabBarController as? AddTracksTabBarController {
            fetcher = (Party.musicService == .spotify) ? SpotifyFetcher() : AppleMusicFetcher()
            fetcher.convert(userTracks: controller.libraryTracksSelected) { [weak self] (tracksFound, tracksNotFound) in
                self?.updateQueues(withTracks: tracksFound)
                self?.alertUser(forTracksCount: tracksNotFound.count)
            }
            updateQueues(withTracks: controller.tracksSelected)
        }
    }
    
    private func updateQueues(withTracks tracks: [Track]) {
        Party.tracksFromMyself.append(contentsOf: tracks)
        personalQueue = personalQueue.union(Set(tracks))
        Party.tracksQueue.append(contentsOf: tracks)
        
        if Party.tracksQueue.count == tracks.count && isHost {
            musicPlayer.startPlayer()
        }
    }
    
    private func alertUser(forTracksCount count: Int) {
        guard count > 0 else { return }
        
        hideConnectionRelatedViewsOnAlert()
        resendButton.isHidden = true
        alertLabel.text = "\(count) library song\(count > 1 ? "s" : "") not found"
        displayAlert()
        let _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.hideAlert()
        }
    }
    
    func showFailedTracks() {
        let count = MultipeerManager.tracksFailedToSend.count
        guard count > 0 else { return }
        
        hideConnectionRelatedViewsOnAlert()
        resendButton.isHidden = false
        alertLabel.text = "\(count) request\(count > 1 ? "s" : "") failed to send"
        displayAlert()
        
        let _ = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
            if self != nil && self!.connectionStatus == .connected {
                self?.hideAlert()
            }
        }
    }
    
    @IBAction func resendTracks() {
        hideAlert()
        networkManager?.send(tracks: MultipeerManager.tracksFailedToSend)
    }
    
    
    // MARK: NetworkManagerDelegate
    
    func resetManager() {
        networkManager = nil
        networkManager = MultipeerManager(isHost: self.isHost)
        networkManager?.delegate = self
    }
    
    func updateStatus(withState state: MCSessionState) {
        if !isHost {
            DispatchQueue.main.async { [weak self] in
                self?.connectionStatus = state
            }
        }
    }
    
    func setup(withParty party: Party) {
        Party.name = type(of: party).name
        Party.musicService = type(of: party).musicService
        Party.cookie = type(of: party).cookie
    }
    
    func update(usingPosition position: TimeInterval) {
        MusicPlayer.currentPosition = position
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
    
}
