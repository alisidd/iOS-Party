//
//  SpotifyConstants.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

struct SpotifyConstants {
    static let spotifyPlayerDidLoginNotification = Notification.Name("spotifyPlayerDidLoginNotification")
    
    static let clientID = "308657d9662146ecae57855ac2a01045"
    static let clientSecret = "ac96ee90c147415ea3ca38eb5563c0ea"
    
    static let redirectURL = URL(string: "partyapp://returnafterlogin")
    static let swapURL = URL(string: "https://wej-refresh-token.herokuapp.com/swap")
    static let refreshURL = URL(string: "https://wej-refresh-token.herokuapp.com/refresh")
    
    static var authorizationToken: String {
        return Data((clientID + ":" + clientSecret).utf8).base64EncodedString()
    }
}
