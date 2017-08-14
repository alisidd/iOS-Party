//
//  SpotifyURLFactory.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
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
        let disallowedChars = CharacterSet(charactersIn: "()[],.!?")
        let escapedTerm = term.components(separatedBy: disallowedChars).joined(separator: " ").replacedWhiteSpaceForURL
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/search"
        
        let urlParameters = ["q": escapedTerm,
                             "type": "track"]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createTrackRequest(forID id: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/tracks/\(id.components(separatedBy: ":")[1])"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createUserAlbumsRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/me/albums"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createUserPlaylistsRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/me/playlists"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createUserTracksRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/me/tracks"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createMyPlaylistsRequest(forOwnerID ownerID: String, forPlaylistID playlistID: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/users/\(ownerID)/playlists/\(playlistID)"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(SpotifyAuthorizationManager.getAuth().session.accessToken!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createPlaylistsRequest(forOwnerID ownerID: String, forPlaylistID playlistID: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/users/\(ownerID)/playlists/\(playlistID)"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createPlaylistsIDRequest(forCategoryID categoryID: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseSpotifyWebAPI
        urlComponents.path = "/v1/browse/categories/\(categoryID)/playlists"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.addValue("Bearer \(Party.cookie!)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
}
