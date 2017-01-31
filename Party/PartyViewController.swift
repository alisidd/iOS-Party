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

protocol NetworkManagerDelegate: class {
    func connectedDevicesChanged(_ manager : NetworkServiceManager, connectedDevices: [String])
    func amHost() -> Bool
    func sendPartyInfo(toSession session: MCSession)
    func setupParty(withName name: String)
    func addTracksFromPeer(withTracks tracks: [String])
}

protocol UpdatePartyDelegate: class {
    func updateEveryonesTableView()
    //func addTracksFromPeer(withTracks tracks: [String])
}

protocol UpdateTableDelegate: class {
    func reloadTableIfPlayingTrack()
}

class PartyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, NetworkManagerDelegate, UpdatePartyDelegate {
    
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var tracksTableView: UITableView!
    
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
        blurBackgroundImageView()
        setupNavigationBar()
        setDelegates()
        adjustViews()
        
        initializeMusicPlayer()
    }
    
    func updateEveryonesTableView() {
        // Update own table view
        DispatchQueue.main.async {
            self.tracksTableView.reloadData()
        }
        
        // Update peers tableview
        if isHost {
            sendTracksToPeers(forTracks: party.tracksQueue)
        } else {
            sendTracksToPeers(forTracks: party.tracksFromPeers)
            print(party.tracksFromPeers)
            party.tracksFromPeers.removeAll()
        }
    }
    var i = 0
    
    func sendTracksToPeers(forTracks tracks: [Track]) {
        let tracksIDString = Track.idOfTracks(tracks)
        if !tracksIDString.isEmpty {
            tracksListManager.sendTracks(tracksIDString)
            for track in self.party.tracksQueue {
                print("Queue \(i) \(track.name)")
            }
            i += 1
        }
    }
    var i = 0
    
    func addTracksFromPeer(withTracks tracks: [String]) {
        let API = RestApiManager()
        
        DispatchQueue.global(qos: .userInteractive).async {
            
            
            for track in tracks {
                print("Queue Before \(self.i) \(track)")
            }
            
            self.i+=1
            
            for trackID in tracks {
                
                API.makeHTTPRequestToSpotifyForSingleTrack(withID: trackID)
            }
            API.dispatchGroup.wait()
            
            if self.isHost {
                self.party.tracksQueue.append(contentsOf: API.tracksList)
                
                if self.party.tracksQueue.count == API.tracksList.count {
                    self.musicPlayer.modifyQueue(withTracks: self.party.tracksQueue)
                }
            } else {
                self.party.tracksQueue = API.tracksList
            }
            
            for track in self.party.tracksQueue {
                print("Queue \(self.i) \(track.name)")
            }
            API.tracksList.removeAll()
        }
    }
    
    private func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    private func setupNavigationBar() {
        self.title = party.partyName
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont(name: "Trajan Pro", size: 23)!, NSForegroundColorAttributeName: UIColor.white]
    }
    
    private func setDelegates() {
        self.tracksTableView.delegate = self
        self.tracksTableView.dataSource = self
        
        tracksListManager.delegate = self
        party.delegate = self
    }
    
    func adjustViews() {
        // Appearance of table view
        tracksTableView.backgroundColor = .clear
        tracksTableView.separatorColor  = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        tracksTableView.contentInset = UIEdgeInsetsMake(0, 0, 110, 0)
        tracksTableView.tableFooterView = UIView()
        tracksTableView.allowsSelection = false
        
        // Gesture
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(PartyViewController.longPressGestureRecognized(gestureRecognizer:)))
        tracksTableView.addGestureRecognizer(recognizer)
    }
    
    func initializeMusicPlayer() {
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
                        self.startAuthenticationFlow(auth!) //Check unwrap
                    }
                }
            } catch {
                print("Error starting player")
            }
            
        }
    }
    
    // MARK: - Spotify Playback
    
    func startAuthenticationFlow(_ authentication: SPTAuth) {
        let authURL = authentication.spotifyWebAuthenticationURL()
       
        NotificationCenter.default.addObserver(self, selector: #selector(PartyViewController.spotifyLogin), name: NSNotification.Name(rawValue: "Successful Login"), object: nil)
        
        UIApplication.shared.open(authURL!, options: [:])
        /*let authViewController = SFSafariViewController(url: authURL!)
        present(authViewController, animated: true)*/
    }
    
    func spotifyLogin() {
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
    
    func playUsingSession(session: SPTSession) {
        musicPlayer.spotifyPlayer?.login(withAccessToken: session.accessToken)
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // Make sure it's a premium account
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        if isPlaying {
            activateAudioSession()
        }
    }
    
    func activateAudioSession() {
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
    
    @IBAction func nextTrackChange(_ sender: UIButton) {
        if party.tracksQueue.count > 0 {
            if personalQueue.contains(party.tracksQueue[0]) {
                personalQueue.remove(at: personalQueue.index(of: party.tracksQueue[0])!)
            }
            party.tracksQueue.removeFirst()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.musicPlayer.modifyQueue(withTracks: self.party.tracksQueue)
            }
        }
    }
    
    // MARK: - Callbacks
    
    func playNextTrack() {
        if party.tracksQueue.count > 1 && musicPlayer.safeToPlayNextTrack() {
            if personalQueue.contains(party.tracksQueue[0]) {
                personalQueue.remove(at: personalQueue.index(of: party.tracksQueue[0])!)
            }
            print("Removing \(party.tracksQueue.removeFirst().name)")
            print("Playing \(party.tracksQueue[0].name)")
            musicPlayer.modifyQueue(withTracks: party.tracksQueue)
            tracksTableView.reloadData()
        }
    }
    
    func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        let recognizer = gestureRecognizer as! UILongPressGestureRecognizer
    }
    
    func fetchImage(forTrack track: Track) -> UIImage? {
        if let url = URL(string: track.highResArtworkURL) {
            do {
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            } catch {
                print("Error trying to get high resolution artwork")
                return track.artwork
            }
        }
        return track.artwork
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Songs" {
            if let controller = segue.destination as? AddSongViewController {
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
                    VC.tracksQueue[0].highResArtwork = self.fetchImage(forTrack: VC.tracksQueue[0])
                }
                
                DispatchQueue.main.async {
                    self.tracksTableView.reloadData()
                    
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
                                            self.tracksTableView.reloadData()
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
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return party.tracksQueue.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CurrentlyPlayingTrack") as!CurrentlyPlayingTrackTableViewCell
            if let unwrappedArtwork = party.tracksQueue[indexPath.row].highResArtwork {
                cell.artwork.image = unwrappedArtwork
            }
            cell.trackName.text = party.tracksQueue[indexPath.row].name
            cell.artistName.text = party.tracksQueue[indexPath.row].artist
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Track") as! TrackInQueueTableViewCell
            
            if let unwrappedArtwork = party.tracksQueue[indexPath.row].artwork {
                cell.artwork.image = unwrappedArtwork
            }
            cell.trackName.text = party.tracksQueue[indexPath.row].name
            cell.artistName.text = party.tracksQueue[indexPath.row].artist
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        
        if !isHost {
            for track in personalQueue {
                if track.id == party.tracksQueue[indexPath.row].id {
                    return true
                }
            }
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            removeFromQueue(track: party.tracksQueue[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func removeFromQueue(track: Track) {
        for trackInQueue in party.tracksQueue {
            if trackInQueue.id == track.id {
                party.tracksQueue.remove(at: party.tracksQueue.index(of: trackInQueue)!)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            tableView.dataSource?.tableView?(
                tableView,
                commit: .delete,
                forRowAt: indexPath
            )
            return
        })
        
        
        deleteButton.backgroundColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        
        return [deleteButton]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.row == 0 ? 350 : 80
    }
    
    // Mark: - UpdateTable
    
    func reloadTableIfPlayingTrack() {
        DispatchQueue.main.async {
            print("Reloading table")
            self.tracksTableView.reloadData()
        }
    }
    
    // MARK: NetworkManagerDelegate
    
    func connectedDevicesChanged(_ manager: NetworkServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    func amHost() -> Bool {
        return isHost
    }
    
    func sendPartyInfo(toSession session: MCSession) {
        if isHost {
            tracksListManager.sendPartyInfo(withTracks: party.tracksQueue, withName: party.partyName, toSession: session)
        }
    }
    
    func setupParty(withName name: String) {
        print("Setting up party using party info received")
        party.partyName = name
        DispatchQueue.main.async {
            self.title = name.uppercased()
        }
    }
}
