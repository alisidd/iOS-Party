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
    
    let serviceController = SKCloudServiceController()
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
            default:
                print("Not authorized")
            }
            
        }
    }
    
    func playTracks(tracks: [Track]) {
        var ids = [String]()
        for track in tracks {
            ids.append(String(track.id))
        }
        player.setQueueWithStoreIDs(ids)
        player.play()
    }
    
}
