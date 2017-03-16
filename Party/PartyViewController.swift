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
    func amHost() -> Bool
    func sendPartyInfo(toSession session: MCSession)
    func setupParty(withName name: String)
    func addTracks(fromPeer peer: MCPeerID, withTracks tracks: [String])
    func removeTrackFromPeer(withTrack track: String)
}

protocol UpdatePartyDelegate: class {
    func updateEveryonesTableView()
}

protocol UpdateCurrentlyPlayingArtworkDelegate: class {
    func reloadTableIfPlayingTrack(forTrack track: Track)
}

class PartyViewController: UIViewController, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, NetworkManagerDelegate, UpdatePartyDelegate {
    
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var currentlyPlayingArtwork: UIImageView!
    @IBOutlet weak var currentlyPlayingTrackName: UILabel!
    @IBOutlet weak var currentlyPlayingArtistName: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var upNextLabel: UILabel!
    var lyricsAndQueueVC: LyricsAndQueuePageViewController {
        get {
            let vc = childViewControllers.first{ $0 is LyricsAndQueuePageViewController }
            return vc as! LyricsAndQueuePageViewController
        }
    }
    
    // MARK: - General Variables
    
    lazy var tracksListManager: NetworkServiceManager = {
        return NetworkServiceManager(self.isHost)
    }()
    private let APIManager = RestApiManager()
    
    var party = Party()
    private var musicPlayer = MusicPlayer() {
        didSet {
            initializeMusicPlayer()
        }
    }
    var isHost = true
    var personalQueue = [Track]()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
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
    
    // MARK: - Modify Queue and Views From Peers
    
    internal func updateEveryonesTableView() {
        // Update own table view
        lyricsAndQueueVC.updateTable(withTracks: party.tracksQueue)
        
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
        if !party.tracksQueue.isEmpty {
            updateArtworkForCurrentlyPlaying()
            currentlyPlayingTrackName.text = party.tracksQueue[0].name
            currentlyPlayingArtistName.text = party.tracksQueue[0].artist
        }
    }
    
    func updateArtworkForCurrentlyPlaying() {
        if let highResArtwork = party.tracksQueue[0].highResArtwork {
            currentlyPlayingArtwork.image = highResArtwork.addGradient()
        } else {
            let trackToSet = party.tracksQueue[0]
            DispatchQueue.global(qos: .userInitiated).async {
                if !self.party.tracksQueue.isEmpty {
                    if trackToSet == self.party.tracksQueue[0] {
                        self.currentlyPlayingArtwork.image = self.fetchImage(forTrack: self.party.tracksQueue[0])?.addGradient()
                    }
                }
            }
        }
    }
    
    // Handles addition and removal of tracks
    private func sendTracksToPeers(forTracks tracks: [Track]) {
        let tracksIDString = Track.idOfTracks(tracks)
        if isHost || (!isHost && !tracks.isEmpty) {
            tracksListManager.sendTracks(tracksIDString)
        }
    }
    
    internal func addTracks(fromPeer peer: MCPeerID, withTracks tracks: [String]) {
        
        APIManager.latestRequest[peer] = tracks
        
        DispatchQueue.global(qos: .userInteractive).async {
            let API = RestApiManager()
            
            for trackID in tracks {
                API.makeHTTPRequestToSpotifyForSingleTrack(withID: trackID)
                API.dispatchGroup.wait()
            }
            
            if let requestTracks = self.APIManager.latestRequest[peer], requestTracks == tracks { // check if this improvement works
                if self.isHost {
                    self.party.tracksQueue.append(contentsOf: API.tracksList)
                    if self.party.tracksQueue.count == API.tracksList.count {
                        print("probably second")
                        self.musicPlayer.modifyQueue(withTracks: self.party.tracksQueue)
                    }
                } else {
                    // fetch high res artwork for host and nonhost only for currently playing track and then later for all other tracks
                    var isOrdered = true
                    for i in 0..<self.party.tracksQueue.count {
                        if !(self.party.tracksQueue[i].id == API.tracksList[i].id) {
                           isOrdered = false
                        }
                    }
                    
                    if isOrdered {
                        self.party.tracksQueue.append(contentsOf: API.tracksList[self.party.tracksQueue.count..<API.tracksList.count])
                    } else {
                        self.party.tracksQueue = API.tracksList
                    }
                }
            }
            
            API.tracksList.removeAll()
            self.APIManager.latestRequest.removeValue(forKey: peer)
        }
    }
    
    private func removeFromOthersQueue(forTrack track: Track) {
        track.id += ":/?r"
        sendTracksToPeers(forTracks: [track])
    }
    
    internal func removeTrackFromPeer(withTrack trackID: String) {
        for trackInQueue in party.tracksQueue {
            if trackInQueue.id == trackID.substring(to: trackID.index(trackID.endIndex, offsetBy: -4)) {
                party.tracksQueue.remove(at: party.tracksQueue.index(of: trackInQueue)!)
            }
        }
    }
    
    // MARK: - General Functions
    
    private func setupNavigationBar() {
        self.title = party.partyName
        navigationController?.navigationBar.isTranslucent = true
        UINavigationBar.appearance().barTintColor = UIColor(red: 0/255, green: 0/255, blue: 45/255, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont(name: "Helvetica Light", size: 23)!, NSForegroundColorAttributeName: UIColor.white]
    }
    
    private func setDelegates() {
        tracksListManager.delegate = self
        party.delegate = self
    }
    
    // TODO: improve this functions name
    private func adjustViews() {
        // Gesture
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(PartyViewController.longPressGestureRecognized(gestureRecognizer:)))
    }
    
    private func initializeMusicPlayer() {
        musicPlayer.party = party
        
        if party.musicService == .appleMusic {
            musicPlayer.hasCapabilities()
            musicPlayer.haveAuthorization()
            musicPlayer.appleMusicPlayer.beginGeneratingPlaybackNotifications()
            NotificationCenter.default.addObserver(self, selector: #selector(PartyViewController.playNextTrack), name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: musicPlayer.appleMusicPlayer)
            
        } else {
            let APIManager = RestApiManager()
            
            let auth = APIManager.getAuthentication()
            musicPlayer.spotifyPlayer?.delegate = self
            musicPlayer.spotifyPlayer?.playbackDelegate = self
            
            do {
                try musicPlayer.spotifyPlayer?.start(withClientId: auth?.clientID)
                DispatchQueue.main.async {
                    if self.isHost {
                        self.startAuthenticationFlow(auth!) //TODO: Check unwrap
                    }
                }
            } catch {
                print("Error starting player")
            }
            
        }
    }
    
    // MARK: - Spotify Playback
    
    private func startAuthenticationFlow(_ authentication: SPTAuth) {
        let authURL = authentication.spotifyWebAuthenticationURL()
       
        NotificationCenter.default.addObserver(self, selector: #selector(PartyViewController.spotifyLogin), name: NSNotification.Name(rawValue: "Successful Login"), object: nil)
        
        UIApplication.shared.open(authURL!, options: [:])
        /*let authViewController = SFSafariViewController(url: authURL!)
        present(authViewController, animated: true)*/
    }
    
    @objc private func spotifyLogin() {
        let userDefaults = UserDefaults.standard
        
        if let sessionDataObj = userDefaults.object(forKey: "SpotifySession") {
            let sessionData = sessionDataObj as! Data
            
            let session = NSKeyedUnarchiver.unarchiveObject(with: sessionData) as! SPTSession
            
            if session.isValid() {
                playUsingSession(session: session)
            } else {
                /*SPTAuth.defaultInstance().renewSession(session) { (error, session) in
                    
                }*/
            }
        }
    }
    
    private func playUsingSession(session: SPTSession) {
        musicPlayer.spotifyPlayer?.login(withAccessToken: session.accessToken)
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
            }, completion:{ (finished) in
                sender.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                UIView.animate(withDuration: 0.25, animations: {
                    sender.alpha = 0.6
                }, completion:nil)
            })
            musicPlayer.playTrack()
        } else {
            UIView.animate(withDuration: 0.1, animations: {
                sender.alpha = 0.0
            }, completion:{ (finished) in
                sender.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                UIView.animate(withDuration: 0.25, animations: {
                    sender.alpha = 0.6
                }, completion:nil)
            })
            musicPlayer.pauseTrack()
        }
    }
    
    // MARK: - Callbacks
    
    @objc private func playNextTrack() {
        setTimer()
        if musicPlayer.safeToPlayNextTrack() && !party.tracksQueue.isEmpty {
            if progressBar.progress == 100 {
                if personalQueue.contains(party.tracksQueue[0]) {
                    personalQueue.remove(at: personalQueue.index(of: party.tracksQueue[0])!)
                }
                removeFromOthersQueue(forTrack: party.tracksQueue[0])
                print("Removing \(party.tracksQueue.removeFirst().name)")
                musicPlayer.modifyQueue(withTracks: party.tracksQueue)
                
                updateCurrentlyPlayingTrack()
                lyricsAndQueueVC.updateTable(withTracks: party.tracksQueue)
            }
        }
    }
    
    func setTimer() {
        let _ = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(PartyViewController.updateProgress), userInfo: nil, repeats: true)
    }
    
    func updateProgress() {
        if !party.tracksQueue.isEmpty {
            if let wholeLength = party.tracksQueue[0].length {
                progressBar.setProgress(Float(musicPlayer.getCurrentPosition())/Float(wholeLength), animated: true)
            }
        }
    }
    
    func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        let recognizer = gestureRecognizer as! UILongPressGestureRecognizer
    }
    
    private func fetchImage(forTrack track: Track) -> UIImage? {
        if let url = URL(string: track.highResArtworkURL) {
            do {
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            } catch {
                print("Error trying to get high resolution artwork")
                return nil
            }
        }
        return nil
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Show Lyrics and Queue" {
            if let controller = segue.destination as? LyricsAndQueuePageViewController {
                controller.party = party
            }
        }
    }
    
    @IBAction func unwindToPartyViewController(_ sender: UIStoryboardSegue) {
        if let VC = sender.source as? AddSongViewController {
            DispatchQueue.global(qos: .userInitiated).async {
                
                self.party.tracksFromPeers.append(contentsOf: VC.tracksQueue)
                self.party.tracksQueue.append(contentsOf: VC.tracksQueue)
                self.personalQueue.append(contentsOf: VC.tracksQueue)
                
                if self.party.tracksQueue.count == VC.tracksQueue.count && self.party.tracksQueue.count > 0 {
                    print("Track changed: \(VC.tracksQueue[0])")
                    self.currentlyPlayingArtwork.image = self.fetchImage(forTrack: VC.tracksQueue[0])?.addGradient()
                }
                
                DispatchQueue.main.async {
                    self.lyricsAndQueueVC.updateTable(withTracks: self.party.tracksQueue)
                    
                    DispatchQueue.global(qos: .userInitiated).async {
                        if self.party.tracksQueue.count == VC.tracksQueue.count {
                            self.musicPlayer.modifyQueue(withTracks: self.party.tracksQueue)
                        }
                        
                        for track in VC.tracksQueue {
                            if let unwrappedArtwork = self.fetchImage(forTrack: track) {
                                track.highResArtwork = unwrappedArtwork
                                if self.party.tracksQueue.count > 0 {
                                    if track == self.party.tracksQueue[0] {
                                        DispatchQueue.main.async {
                                            self.updateCurrentlyPlayingTrack()
                                        }
                                    }
                                }    
                            }
                        }
                        
                        VC.emptyArrays()
                    }
                }
            }
        }
    }
    
    // MARK: NetworkManagerDelegate
    
    internal func connectedDevicesChanged(_ manager: NetworkServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    internal func amHost() -> Bool {
        return isHost
    }
    
    internal func sendPartyInfo(toSession session: MCSession) {
        if isHost {
            tracksListManager.sendPartyInfo(withTracks: party.tracksQueue, withName: party.partyName, toSession: session)
        }
    }
    
    internal func setupParty(withName name: String) {
        print("Setting up party using party info received")
        party.partyName = name
        DispatchQueue.main.async {
            self.title = name.uppercased()
        }
    }
}
