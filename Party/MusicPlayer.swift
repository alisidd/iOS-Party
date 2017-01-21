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

class MusicPlayer {
    
    private let serviceController = SKCloudServiceController()
    let player = MPMusicPlayerController.applicationMusicPlayer()
    
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
            default:
                print("Not authorized")
            }
            
        }
    }
    
    func modifyQueue(withTracks tracks: [Track]) {
        if tracks.count != 0 {
            let ids = [String(tracks[0].id)]
            player.setQueueWithStoreIDs(ids)
            player.play()
        } else {
            player.setQueueWithStoreIDs([])
            player.stop()
        }
    }
    
    func safeToPlayNextTrack() -> Bool {
        return player.playbackState == .stopped && player.nowPlayingItem == nil
    }
    
    func playTracks() {
        player.play()
    }
    
    func skipTrack() {
        player.skipToNextItem()
    }
    
}
