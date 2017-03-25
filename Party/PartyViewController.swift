//
//  PartyViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit
import MediaPlayer
import MultipeerConnectivity

extension UIImage {
    func addGradient() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()
        
        self.draw(at: CGPoint(x: 0, y: 0))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        
        let bottom = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1).cgColor
        let top = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        
        let colors = [top, bottom] as CFArray
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)
        
        let startPoint = CGPoint(x: self.size.width/2, y: 0)
        let endPoint = CGPoint(x: self.size.width/2, y: self.size.height)
        
        context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))
        
        let imageToReturn = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return imageToReturn!
    }
}

protocol NetworkManagerDelegate: class {
    func connectedDevicesChanged(_ manager : NetworkServiceManager, connectedDevices: [String])
    func updateStatus(with state: MCSessionState)
    func amHost() -> Bool
    func sendPartyInfo(toSession session: MCSession)
    func setupParty(withService service: String)
    func addTracks(fromPeer peer: MCPeerID, withTracks tracks: [String])
    func removeTrackFromPeer(withTrack track: String)
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
}

class PartyViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, NetworkManagerDelegate, UpdatePartyDelegate, PartyViewControllerInfoDelegate {
    
    // MARK: - Storyboard Variables
    
    // Currently Playing
    @IBOutlet weak var currentlyPlayingArtwork: UIImageView!
    @IBOutlet weak var currentlyPlayingTrackName: UILabel!
    @IBOutlet weak var currentlyPlayingArtistName: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    
    // Tracks Queue
    @IBOutlet weak var upNextLabel: UILabel!
    
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    var lyricsAndQueueVC: HubAndQueuePageViewController {
        get {
            let vc = childViewControllers.first{ $0 is HubAndQueuePageViewController }
            return vc as! HubAndQueuePageViewController
        }
    }
    
    // Connection Status
    @IBOutlet weak var connectionStatusLabel: UILabel!
    var connectionStatus: MCSessionState {
        get {
            return self.connectionStatus
        }
        set {
            DispatchQueue.main.async {
                self.displayStatusSymbol()
                self.connectionStatusLabel.text = newValue.stringValue()
                
                if newValue == .connected {
                    self.removeReconnectButton()
                    self.removeStatusLabel()
                } else if newValue == .connecting {
                    self.removeReconnectButton()
                    self.lyricsAndQueueVC.expandTracksTable()
                } else {
                    self.displayReconnectButton()
                    self.lyricsAndQueueVC.expandTracksTable()
                }
            }
        }
    }
    @IBOutlet weak var reconnectButton: UIButton!
    
    func displayStatusSymbol() {
        UIView.animate(withDuration: 0.5) {
            self.connectionStatusLabel.isHidden = false
            self.connectionStatusLabel.alpha = 1
        }
    }
    
    func removeStatusLabel() {
        UIView.animate(withDuration: 1, animations: {
            self.connectionStatusLabel.alpha = 0
        }, completion: { (finished) in
            self.connectionStatusLabel.isHidden = true
        })
    }
    
    func displayReconnectButton() {
        view.layoutIfNeeded()
        reconnectButton.isHidden = false
        UIView.animate(withDuration: 0.4) {
            self.reconnectButton.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    func removeReconnectButton() {
        view.layoutIfNeeded()
        reconnectButton.isHidden = true
        UIView.animate(withDuration: 0.4) {
            self.reconnectButton.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func reconnectToParty(_ sender: UIButton) {
        tracksListManager = nil
        tracksListManager = NetworkServiceManager(self.isHost)
        tracksListManager.delegate = self
        connectionStatus = .connecting
    }
    
    // MARK: - General Variables
    
    lazy var tracksListManager: NetworkServiceManager! = {
        return NetworkServiceManager(self.isHost)
    }()
    private let APIManager = RestApiManager()
    
    var party = Party()
    var musicPlayer = MusicPlayer()
    var spotifySession: SPTSession?
    var isHost = true
    var personalQueue = [Track]()
    var cache = [Track]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        adjustViews()
        
        initializeMusicPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    // MARK: - General Functions
    
    private func setDelegates() {
        tracksListManager.delegate = self
        party.delegate = self
        musicPlayer.spotifyPlayer?.delegate = self
        musicPlayer.spotifyPlayer?.playbackDelegate = self
    }
    
    private func adjustViews() {
        progressBar.isHidden = true
        hideCurrentlyPlayingArtwork()
        lyricsAndQueueVC.expandTracksTable()
        if !isHost {
            playPauseButton.isHidden = true
            connectionStatus = .notConnected
        }
    }
    
    func initializeMusicPlayer() {
        if isHost {
            setTimer()
        }
        
        if party.musicService == .spotify {
            playUsingSession()
        } else {
            musicPlayer.appleMusicPlayer.beginGeneratingPlaybackNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(PartyViewController.playNextTrack), name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer.appleMusicPlayer)
        }
    }
    
    // MARK: - Modify Queue and Views From Peers
    
    internal func updateEveryonesTableView() {
        // Update own table view
        lyricsAndQueueVC.updateTable()
        
        updateCurrentlyPlayingTrack()
        
        // Update peers tableview
        if isHost {
            sendTracksToPeers(forTracks: party.tracksQueue)
        } else {
            sendTracksToPeers(forTracks: party.tracksFromPeers)
            party.tracksFromPeers.removeAll()
        }
    }
    
    func updateCurrentlyPlayingTrack() {
        DispatchQueue.main.async {
            if !self.party.tracksQueue.isEmpty {
                if self.party.tracksQueue.count == 1 {
                    self.lyricsAndQueueVC.minimizeTracksTable()
                }
                self.updateArtworkForCurrentlyPlaying()
                self.currentlyPlayingTrackName.text = self.party.tracksQueue[0].name
                self.currentlyPlayingArtistName.text = self.party.tracksQueue[0].artist
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
    
    func showCurrentlyPlayingArtwork() {
        DispatchQueue.main.async {
            self.currentlyPlayingArtwork.isHidden = false
            self.currentlyPlayingTrackName.isHidden = false
            self.currentlyPlayingArtistName.isHidden = false
            if self.isHost {
                self.playPauseButton.isHidden = false
            }
        }
    }
    
    func hideCurrentlyPlayingArtwork() {
        DispatchQueue.main.async {
            self.currentlyPlayingArtwork.isHidden = true
            self.currentlyPlayingTrackName.isHidden = true
            self.currentlyPlayingArtistName.isHidden = true
            self.playPauseButton.isHidden = true
            self.lyricsAndQueueVC.expandTracksTable()
        }
    }
    
    // Handles addition and removal of tracks
    private func sendTracksToPeers(forTracks tracks: [Track]) {
        let tracksIDString = id(ofTracks: tracks)
        if isHost || (!isHost && !tracks.isEmpty) {
            tracksListManager.sendTracks(tracksIDString)
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
    
    internal func addTracks(fromPeer peer: MCPeerID, withTracks tracks: [String]) {
        
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
    
    internal func removeFromOthersQueue(forTrack track: Track) {
        track.id += ":/?r"
        sendTracksToPeers(forTracks: [track])
    }
    
    internal func removeTrackFromPeer(withTrack trackID: String) {
        let id = trackID.components(separatedBy: ":")[0]
        
        for trackInQueue in party.tracksQueue {
            if id == trackInQueue.id {
                party.tracksQueue.remove(at: party.tracksQueue.index(of: trackInQueue)!)
                lyricsAndQueueVC.updateTable()
            }
        }
        
        if party.tracksQueue.isEmpty {
            lyricsAndQueueVC.expandTracksTable()
        }
    }
    
    // MARK: - Playback
    
    private func playUsingSession() {
        if let session = spotifySession {
            musicPlayer.spotifyPlayer?.login(withAccessToken: session.accessToken)
        }
    }
    
    internal func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // Make sure it's a premium account
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            activateAudioSession()
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePosition position: TimeInterval) {
        if let wholeLength = party.tracksQueue[0].length {
            progressBar.setProgress(Float(position)/Float(wholeLength), animated: true)
        }
    }
    
    private func activateAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    internal func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
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
        print(progressBar.progress)
        if musicPlayer.safeToPlayNextTrack() && !party.tracksQueue.isEmpty && progressBar.progress > 0.96 {
            if personalQueue.contains(party.tracksQueue[0]) {
                personalQueue.remove(at: personalQueue.index(of: party.tracksQueue[0])!)
            }
            removeFromOthersQueue(forTrack: party.tracksQueue[0])
            print("Removing \(party.tracksQueue.removeFirst().name)")
            musicPlayer.modifyQueue(withTracks: party.tracksQueue)
            
            updateEveryonesTableView()
            
            if self.party.tracksQueue.isEmpty {
                self.lyricsAndQueueVC.expandTracksTable()
            }
        }
    }
    
    func setTimer() {
        let _ = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] (timer) in
            self?.updateProgress()
        }
    }
    
    func updateProgress() {
        if !party.tracksQueue.isEmpty {
            if let wholeLength = party.tracksQueue[0].length {
                progressBar.setProgress(Float(musicPlayer.getCurrentPosition())/Float(wholeLength), animated: true)
            }
        }
        tracksListManager.advertise()
        
    }
    
    private func fetchImage(forTrack track: Track, setCurrentlyPlaying: Bool) -> UIImage? {
        if let url = URL(string: track.highResArtworkURL) {
            do {
                let data = try Data(contentsOf: url)
                if setCurrentlyPlaying {
                    setCurrentlyPlayingImage(withImage: UIImage(data: data))
                }
                
                return UIImage(data: data)
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
                
                if self.party.tracksQueue.count == VC.tracksQueue.count {
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
            tracksListManager.sendPartyInfo(withTracks: party.tracksQueue, forService: party.musicService, toSession: session)
        }
    }
    
    internal func setupParty(withService service: String) {
        print("Setting up party using party info received")
        if service == "s" {
            party.musicService = .spotify
        } else {
            party.musicService = .appleMusic
        }
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
}
