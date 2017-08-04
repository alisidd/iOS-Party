//
//  SpotifyURLFactory.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

struct SpotifyURLFactory {
    private static let baseAccountsURL = "accounts.spotify.com"
    private static let baseSpotifyWebAPI = "api.spotify.com"
    
    static func createAccessTokenRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAccountsURL
        urlComponents.path = "/api/token"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Basic \(SpotifyConstants.authorizationToken)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = "grant_type=client_credentials".data(using: String.Encoding.utf8)
        
        return urlRequest
    }
    
    static func createSearchRequest(forTerm term: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/search"
        
        let urlParameters = ["q": term.replacingOccurrences(of: " ", with: "+"),
                             "type": "track"]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
    
    static func createTrackRequest(forID id: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/tracks/\(id.components(separatedBy: ":")[1])"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        return urlRequest
    }
}
