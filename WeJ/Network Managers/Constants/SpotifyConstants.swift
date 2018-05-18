//
//  SpotifyConstants.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

struct SpotifyConstants {
    
    static let spotifyPlayerDidLoginNotification = Notification.Name("spotifyPlayerDidLoginNotification")
    
    static let clientID = PrivateConfig.spotifyClientID
    static let clientSecret = PrivateConfig.spotifyClientSecret
    
    static let redirectURL = PrivateConfig.spotifyRedirectURL
    static let swapURL = URL(string: "http://\(PrivateConfig.webServerURL):\(PrivateConfig.spotifyWebServerPort)/swap")
    static let refreshURL = URL(string: "http://\(PrivateConfig.webServerURL):\(PrivateConfig.spotifyWebServerPort)/refresh")
    
    static var authorizationToken: String {
        return Data((clientID + ":" + clientSecret).utf8).base64EncodedString()
    }
    
    static let maxInitialLowRes = 5
    
}
