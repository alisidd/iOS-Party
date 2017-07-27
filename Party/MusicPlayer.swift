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
    // MARK: - Music Player Variables
    
    var appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
    var spotifyPlayer = SPTAudioStreamingController.sharedInstance()
    
    // MARK: - General Variables
    
    var musicService: MusicService!
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
    
    // FIXME: - Doesn't always work
    func safeToPlayNextTrack() -> Bool {
        return appleMusicPlayer.playbackState == .stopped
    }
    
    // FIXME: - hard fails here randomly
    func isPaused() -> Bool {
        return musicService == .appleMusic ? appleMusicPlayer.playbackState == .paused : spotifyPlayer?.playbackState.isPlaying == false
    }
    
    // MARK: - Playback
    
    func modifyQueue(withTracks tracks: [Track]) {
        DispatchQueue.main.async {
            BackgroundTask.startBackgroundTask()
            if self.musicService == .appleMusic {
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
        if musicService == .appleMusic {
            appleMusicPlayer.play()
        } else {
            spotifyPlayer?.setIsPlaying(true, callback: nil)
        }
        
    }
    
    func pauseTrack() {
        BackgroundTask.stopBackgroundTask()
        if musicService == .appleMusic {
            appleMusicPlayer.pause()
        } else {
            spotifyPlayer?.setIsPlaying(false, callback: nil)
        }
    }
}
