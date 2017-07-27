//
//  SpotifyURLFactory.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

struct SpotifyURLFactory {
    private static let baseAccountsURLString = "accounts.spotify.com"
    
    static func createAccessTokenRequest() -> URLRequest {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAccountsURLString
        urlComponents.path = "/api/token"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic \(SpotifyConstants.authorizationToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "grant_type=client_credentials".data(using: String.Encoding.utf8)
        
        return urlRequest
    }
}
