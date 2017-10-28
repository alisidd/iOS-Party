//
//  AppleMusicURLFactory.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/31/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

struct AppleMusicURLFactory {
    private static let baseAppleMusicAPI = "api.music.apple.com"
    
    static func createSearchRequest(forTerm term: String) -> URLRequest {
        let disallowedChars = CharacterSet(charactersIn: "()[],'.!?")
        let escapedTerm = term.components(separatedBy: disallowedChars).joined(separator: " ").replacedWhiteSpaceForURL
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAppleMusicAPI
        urlComponents.path = "/v1/catalog/\(Party.cookie!)/search"
        
        let urlParameters = ["term": escapedTerm,
                             "types": "songs",
                             "limit": "20"]
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
    
    static func createSearchHintsRequest(forTerm term: String) -> URLRequest {
        let disallowedChars = CharacterSet(charactersIn: "()[],'.!?")
        let escapedTerm = term.components(separatedBy: disallowedChars).joined(separator: " ").replacedWhiteSpaceForURL
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAppleMusicAPI
        urlComponents.path = "/v1/catalog/us/search/hints"
        
        let urlParameters = ["term": escapedTerm,
                             "types": "songs",
                             "limit": "7"]
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
    
    static func createMostPlayedRequest() -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAppleMusicAPI
        urlComponents.path = "/v1/catalog/\(Party.cookie!)/charts"
        
        let urlParameters = ["chart": "most-played",
                             "types": "songs",
                             "limit": "20"]
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
}
