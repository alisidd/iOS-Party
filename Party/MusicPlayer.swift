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
    let player = MPMusicPlayerController.systemMusicPlayer()
    let commandCenter = MPRemoteCommandCenter.shared()

    
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
                self.player.beginGeneratingPlaybackNotifications()
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
            self.player.pause()
            return MPRemoteCommandHandlerStatus.success
        }
        
        commandCenter.playCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.player.prepareToPlay()
            self.player.play()
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    func modifyQueue(withTracks tracks: [Track]) {
        if tracks.count != 0 {
            let ids = [String(tracks[0].id)]
            player.setQueueWithStoreIDs(ids)
            playTrack()
        } else {
            player.setQueueWithStoreIDs([])
            player.stop()
        }
    }
    
    func safeToPlayNextTrack() -> Bool {
        return player.playbackState == .stopped && player.nowPlayingItem == nil
    }
    
    @objc func playTrack() {
        player.prepareToPlay()
        player.play()
    }
    
    @objc func pauseTrack() {
        player.pause()
    }
    
    
    func isPaused() -> Bool {
        return player.playbackState == .paused
    }
    
}
