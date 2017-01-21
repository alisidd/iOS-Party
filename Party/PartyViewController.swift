//
//  PartyViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit
import MediaPlayer

protocol updateTracksQueue: class {
    func addToQueue(track: Track)
    func removeFromQueue(track: Track)
    func tracksQueue(hasTrack track: Track) -> Bool
}

class PartyViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, updateTracksQueue {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var tracksTableView: UITableView!
    
    //let tracksListManager = NetworkServiceManager() // Holds the tracks for the current party & advertises the current party
    
    private var party = Party()
    private var musicPlayer = MusicPlayer()
    private var tracksQueue = [Track]() {
        didSet
        {
            self.tracksTableView.reloadData()
            initializeMusicPlayer()
        }
    }
    
    func initializeVariables(withParty partyMade: Party) {
        party.partyName = partyMade.partyName
        party.musicService = partyMade.musicService
        party.genres = partyMade.genres
        //tracksListManager.partyName = party.partyName
        //tracksListManager.isHost = true // Setup as host so browse & advertise
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
        setupNavigationBar()
        setDelegates()
        adjustViews()
        
        initializeMusicPlayer()
    }
    
    private func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    private func setupNavigationBar() {
        self.title = party.partyName.uppercased()
        navigationController?.navigationBar.isTranslucent = true
    }
    
    private func setDelegates() {
        self.tracksTableView.delegate = self
        self.tracksTableView.dataSource = self
        
        //tracksListManager.delegate = self
    }
    
    func adjustViews() {
        // Appearance
        tracksTableView.backgroundColor = .clear
        tracksTableView.separatorColor  = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
        tracksTableView.tableFooterView = UIView()
        tracksTableView.allowsSelection = false
        
        // Gesture
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(PartyViewController.longPressGestureRecognized(gestureRecognizer:)))
        tracksTableView.addGestureRecognizer(recognizer)
    }
    
    func initializeMusicPlayer() {
        musicPlayer.hasCapabilities()
        musicPlayer.haveAuthorization()
        NotificationCenter.default.addObserver(self, selector: #selector(PartyViewController.playNextTrack), name:NSNotification.Name.MPMusicPlayerControllerPlaybackStateDidChange, object: MPMusicPlayerController.applicationMusicPlayer())
    }
    
    // Implement these in the cell itself!!
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
        if tracksQueue.count > 0 {
            tracksQueue.removeFirst()
            musicPlayer.modifyQueue(withTracks: tracksQueue)
        }
    }
    
    func playNextTrack() {
        if tracksQueue.count > 1 && musicPlayer.safeToPlayNextTrack() {
            print("Removing \(tracksQueue.removeFirst().name)")
            print("Playing \(tracksQueue[0].name)")
            musicPlayer.modifyQueue(withTracks: tracksQueue)
        }
    }
    
    func longPressGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        let recognizer = gestureRecognizer as! UILongPressGestureRecognizer
    }
    
    func addToQueue(track: Track) {
        tracksQueue.insert(track, at: tracksQueue.count)
        if tracksQueue.count == 1 {
            musicPlayer.modifyQueue(withTracks: tracksQueue)
        }
    }
    
    func removeFromQueue(track: Track) {
        for trackInQueue in tracksQueue {
            if trackInQueue.id == track.id {
                tracksQueue.remove(at: tracksQueue.index(of: trackInQueue)!)
            }
        }
    }
    
    func updateTracksQueue(withQueue queue: [Track]) {
        tracksQueue = queue
    }
    
    func tracksQueue(hasTrack track: Track) -> Bool {
        for trackInQueue in tracksQueue {
            if track.id == trackInQueue.id {
                return true
            }
        }
        return false
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Songs" {
            if let controller = segue.destination as? AddSongViewController {
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                controller.party = party
                controller.delegate = self
            }
        }
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracksQueue.count
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
            if let unwrappedArtwork = fetchImage(forTrack: tracksQueue[indexPath.row]) {
                cell.artwork.image = unwrappedArtwork
            }
            cell.trackName.text = tracksQueue[indexPath.row].name
            cell.artistName.text = tracksQueue[indexPath.row].artist
            
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Track") as! TrackInQueueTableViewCell
            
            if let unwrappedArtwork = tracksQueue[indexPath.row].artwork {
                cell.artwork.image = unwrappedArtwork
            }
            cell.trackName.text = tracksQueue[indexPath.row].name
            cell.artistName.text = tracksQueue[indexPath.row].artist
            
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != 0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            removeFromQueue(track: tracksQueue[indexPath.row])
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
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
}

// MARK: NetworkManagerDelegate
/*
extension PartyViewController: NetworkManagerDelegate {
    
    func connectedDevicesChanged(_ manager: NetworkServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    func messageChanged(_ manager: NetworkServiceManager, messageString: String) {
        OperationQueue.main.addOperation { () -> Void in
            print(messageString)
        }
    }
    
}*/
