//
//  AppleMusicURLFactory.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/31/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

struct AppleMusicURLFactory {
    private static let baseAppleMusicAPI = "api.music.apple.com"
    
    static func createSearchRequest(forTerm term: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAppleMusicAPI
        urlComponents.path = "/v1/catalog/\(Party.cookie!)/search"
        
        let urlParameters = ["term": term.replacingOccurrences(of: " ", with: "+"),
                             "limit": "20",
                             "types": "songs"]
        var queryItems = [URLQueryItem]()
        for (key, value) in urlParameters {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        urlComponents.queryItems = queryItems
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(AppleMusicConstants.developerToken)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
    
    static func createTrackRequest(forID id: String) -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAppleMusicAPI
        urlComponents.path = "/v1/catalog/\(Party.cookie!)/songs/\(id.components(separatedBy: ":")[1])"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(AppleMusicConstants.developerToken)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
}
