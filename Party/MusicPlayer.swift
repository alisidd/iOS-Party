//
//  MusicPlayer.swift
//  Party
//
//  Created by Ali Siddiqui on 1/20/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer

class MusicPlayer {
    
    weak var delegate: AppleMusicAuthorizationAlertDelegate?
    
    // MARK: - Apple Music Variables
    var appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
    let authorizationDispatchGroup = DispatchGroup()
    var isAuthorized = false
    
    // MARK: - Spotify Variables
    
    var spotifyPlayer = SPTAudioStreamingController.sharedInstance()
    
    // MARK: - General Variables
    
    var party = Party()
    var currentPosition: TimeInterval?
    
    // MARK: - General Functions
    
    init() {
        initializeCommandCenter()
        setupControlEvents()
    }
    
    private func initializeCommandCenter() {
        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
    }
    
    private func setupControlEvents() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.pauseTrack()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
            self.playTrack()
            return .success
        }
    }
    
    // MARK: - Apple Music Functions
    
    func hasCapabilities() {
        SKCloudServiceController().requestCapabilities { (capability, error) in
            if capability.contains(.musicCatalogPlayback) || capability.contains(.addToCloudMusicLibrary) {
                print("Has Apple Music capabilities")
            } else {
                self.delegate?.postAlertForNoAppleMusic()
            }
        }
    }
    
    func haveAuthorization() {
        // If user has pressed Don't allow, move them to the settings
        authorizationDispatchGroup.enter()
        SKCloudServiceController.requestAuthorization { (status) in
            switch status {
            case .authorized:
                self.isAuthorized = true
            case .denied:
                self.delegate?.postAlertForSettings()
                fallthrough
            default:
                self.isAuthorized = false
            }
            self.authorizationDispatchGroup.leave()
        }
    }
    
    func safeToPlayNextTrack() -> Bool {
        print(appleMusicPlayer.playbackState == .stopped)
        return appleMusicPlayer.playbackState == .stopped
    }
    
    // TODO: - hard fails here randomly
    func isPaused() -> Bool {
        return party.musicService == .appleMusic ? appleMusicPlayer.playbackState == .paused : spotifyPlayer?.playbackState.isPlaying == false
    }
    
    // MARK: - Playback
    
    func modifyQueue(withTracks tracks: [Track]) {
        DispatchQueue.main.async {
            BackgroundTask.startBackgroundTask()
            if self.party.musicService == .appleMusic {
                self.modifyAppleMusicQueue(withTrack: tracks)
            } else {
                self.modifySpotifyQueue(withTrack: tracks)
            }
        }
    }
    
    func modifyAppleMusicQueue(withTrack tracks: [Track]) {
        if !tracks.isEmpty {
            let id = [tracks[0].id]
            appleMusicPlayer.setQueueWithStoreIDs(id)
            playTrack()
        } else {
            appleMusicPlayer.setQueueWithStoreIDs([])
            appleMusicPlayer.stop()
        }
    }
    
    func modifySpotifyQueue(withTrack tracks: [Track]) {
        if !tracks.isEmpty {
            try? AVAudioSession.sharedInstance().setActive(true)
            spotifyPlayer?.playSpotifyURI("spotify:track:" + tracks[0].id, startingWith: 0, startingWithPosition: 0, callback: nil)
        } else {
            spotifyPlayer?.skipNext(nil)
        }
    }
    
    func playTrack() {
        BackgroundTask.startBackgroundTask()
        if party.musicService == .appleMusic {
            appleMusicPlayer.play()
        } else {
            spotifyPlayer?.setIsPlaying(true, callback: nil)
        }
        
    }
    
    func pauseTrack() {
        BackgroundTask.stopBackgroundTask()
        if party.musicService == .appleMusic {
            appleMusicPlayer.pause()
        } else {
            spotifyPlayer?.setIsPlaying(false, callback: nil)
        }
    }
}
