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
    
    let musicService = Party.musicService
    
    // MARK: - General Variables
    
    static var currentPosition: TimeInterval?
    
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
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.pauseTrack()
            return .success
        }
        
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ -> MPRemoteCommandHandlerStatus in
            self?.playTrack()
            return .success
        }
    }
    
    // FIXME: - Doesn't always work
    func safeToPlayNextTrack() -> Bool {
        return appleMusicPlayer.playbackState == .stopped
    }
    
    func isPaused() -> Bool {
        return musicService == .spotify ? spotifyPlayer?.playbackState.isPlaying == false : appleMusicPlayer.playbackState == .paused
    }
    
    // MARK: - Playback
    
    func startPlayer(withTracks tracks: [Track]) {
        DispatchQueue.main.async {
            if self.musicService == .spotify {
                self.startSpotifyPlayer(withTracks: tracks)
            } else {
                BackgroundTask.startBackgroundTask()
                self.startAppleMusicPlayer(withTracks: tracks)
            }
        }
    }
    
    private func startSpotifyPlayer(withTracks tracks: [Track]) {
        if !tracks.isEmpty {
            try? AVAudioSession.sharedInstance().setActive(true)
            spotifyPlayer?.playSpotifyURI("spotify:track:" + tracks[0].id, startingWith: 0, startingWithPosition: 0, callback: nil)
        } else {
            spotifyPlayer?.skipNext(nil)
        }
    }
    
    private func startAppleMusicPlayer(withTracks tracks: [Track]) {
        if !tracks.isEmpty {
            let id = [tracks[0].id]
            appleMusicPlayer.setQueueWithStoreIDs(id)
            playTrack()
        } else {
            appleMusicPlayer.setQueueWithStoreIDs([])
            appleMusicPlayer.stop()
        }
    }
    
    func stopPlayer() {
        if musicService == .spotify && spotifyPlayer!.playbackState.isPlaying {
            spotifyPlayer?.setIsPlaying(false, callback: nil)
        }
        
        if musicService == .appleMusic && appleMusicPlayer.playbackState == .playing {
            BackgroundTask.stopBackgroundTask()
            appleMusicPlayer.stop()
        }
    }
    
    func playTrack() {
        if musicService == .spotify {
            spotifyPlayer?.setIsPlaying(true, callback: nil)
        } else {
            BackgroundTask.startBackgroundTask()
            appleMusicPlayer.play()
        }
        
    }
    
    func pauseTrack() {
        if musicService == .spotify {
            spotifyPlayer?.setIsPlaying(false, callback: nil)
        } else {
            BackgroundTask.stopBackgroundTask()
            appleMusicPlayer.pause()
        }
    }
}
