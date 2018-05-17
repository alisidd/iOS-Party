//
//  MusicPlayer.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 1/20/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer

class MusicPlayer {
    
    // MARK: - Music Player Variables
    
    var appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer
    var spotifyPlayer = SPTAudioStreamingController.sharedInstance()
    
    let musicService = Party.musicService
    
    // MARK: - General Variables
    
    var isScrubbing = false
    
    var currentPosition: TimeInterval? {
        get {
            return (musicService == .spotify) ? spotifyPlayer?.playbackState?.position : appleMusicPlayer.currentPlaybackTime
        }
    }
    
    var isSafeToPlayNextTrack: Bool {
        return !Party.tracksQueue.isEmpty && appleMusicPlayer.playbackState == .stopped
    }
    
    var isPaused: Bool {
        return musicService == .spotify ? spotifyPlayer?.playbackState.isPlaying == false : appleMusicPlayer.playbackState == .paused
    }
    
    // MARK: - Playback
    
    func preparePlayer() {
        if Party.musicService == .spotify {
            spotifyPlayer?.setTargetBitrate(.low, callback: nil)
        } else {
            appleMusicPlayer.beginGeneratingPlaybackNotifications()
        }
    }
    
    func startPlayer() {
        DispatchQueue.main.async {
            if self.musicService == .spotify {
                self.startSpotifyPlayer(withTracks: Party.tracksQueue)
            } else {
                self.startAppleMusicPlayer(withTracks: Party.tracksQueue)
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
            appleMusicPlayer.setQueue(with: [tracks[0].id])
            playTrack()
        } else if BackgroundTask.isPlaying {
            BackgroundTask.stopBackgroundTask()
            appleMusicPlayer.setQueue(with: [])
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
            if #available(iOS 10.1, *) {
                appleMusicPlayer.prepareToPlay { (_) in
                    self.appleMusicPlayer.play()
                }
            } else {
                appleMusicPlayer.prepareToPlay()
                appleMusicPlayer.play()
            }
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
    
    func scrubTrack(toPosition position: TimeInterval, callback: @escaping SPTErrorableOperationCallback) {
        if musicService == .spotify {
            spotifyPlayer?.seek(to: position, callback: callback)
        }
    }
    
}
