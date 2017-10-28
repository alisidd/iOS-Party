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
    
    static let clientID = "308657d9662146ecae57855ac2a01045"
    static let clientSecret = "2ee61ecb3172468c8007c4d682c8d023"
    
    static let redirectURL = URL(string: "partyapp://returnafterlogin")
    static let swapURL = URL(string: "https://wej-refresh-token.herokuapp.com/swap")
    static let refreshURL = URL(string: "https://wej-refresh-token.herokuapp.com/refresh")
    
    static var authorizationToken: String {
        return Data((clientID + ":" + clientSecret).utf8).base64EncodedString()
    }
    
    static let maxInitialLowRes = 5
    
}
