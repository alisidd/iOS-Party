//
//  MusicPlayer.swift
//  Party
//
//  Created by Ali Siddiqui on 1/20/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import StoreKit
import MediaPlayer

class MusicPlayer: NSObject {
    private let serviceController = SKCloudServiceController()
    let appleMusicPlayer = MPMusicPlayerController.applicationMusicPlayer()
    var spotifyPlayer = SPTAudioStreamingController.sharedInstance()
    let commandCenter = MPRemoteCommandCenter.shared()
    
    var party = Party()

    
    func hasCapabilities() {
        serviceController.requestCapabilities{ (capability, error) in
            if capability.contains(.musicCatalogPlayback) || capability.contains(.addToCloudMusicLibrary) {
                print("Has capabilities")
            } else {
                print("Doesn't have capabilities")
            }
        }
    }
    
    func haveAuthorization() {
        // If user has pressed Don't allow, move them to the settings
        SKCloudServiceController.requestAuthorization { (status) in
            switch status {
            case .authorized:
                print("Authorized")
                self.appleMusicPlayer.beginGeneratingPlaybackNotifications()
                self.initializeCommandCenter()
            default:
                print("Not authorized")
            }
            
        }
    }
    
    func initializeCommandCenter() {
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.playCommand.isEnabled = true
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        commandCenter.pauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.appleMusicPlayer.pause()
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.playCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.appleMusicPlayer.prepareToPlay()
            self.appleMusicPlayer.play()
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    func modifyQueue(withTracks tracks: [Track]) {
        if party.musicService == .appleMusic {
            if tracks.count != 0 {
                let ids = [tracks[0].id]
                appleMusicPlayer.setQueueWithStoreIDs(ids)
                playTrack()
            } else {
                appleMusicPlayer.setQueueWithStoreIDs([])
                appleMusicPlayer.stop()
            }
        } else {
            if tracks.count != 0 {
                spotifyPlayer?.playSpotifyURI("spotify:track:" + tracks[0].id, startingWith: 0, startingWithPosition: 0, callback: nil)
                //spotifyPlayer?.queueSpotifyURI("spotify:track:" + tracks[0].id, callback: nil)
                //playTrack()
            } else {
                spotifyPlayer?.skipNext(nil)
            }
        }
    }
    
    func safeToPlayNextTrack() -> Bool {
        return appleMusicPlayer.playbackState == .stopped && appleMusicPlayer.nowPlayingItem == nil
    }
    
    @objc func playTrack() {
        print("Trying")
        if party.musicService == .appleMusic {
            appleMusicPlayer.prepareToPlay()
            appleMusicPlayer.play()
        } else {
            spotifyPlayer?.setIsPlaying(true, callback: nil)
        }
        
    }
    
    @objc func pauseTrack() {
        if party.musicService == .appleMusic {
            appleMusicPlayer.pause()
        } else {
            spotifyPlayer?.setIsPlaying(false, callback: nil)
        }
    }
    
    
    func isPaused() -> Bool {
        return party.musicService == .appleMusic ? appleMusicPlayer.playbackState == .paused : spotifyPlayer?.playbackState.isPlaying == false
    }
    
}
