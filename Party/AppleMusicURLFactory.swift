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
    
    static func createTrackRequest(forID id: String) -> URLRequest {
        let id = id.components(separatedBy: ":")[1]
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseAppleMusicAPI
        urlComponents.path = "/v1/catalog/\(Party.countryCode!)/songs/\(id)"
        
        var urlRequest = URLRequest(url: urlComponents.url!)
        urlRequest.httpMethod = "GET"
        urlRequest.addValue("Bearer \(AppleMusicConstants.developerToken)", forHTTPHeaderField: "Authorization")
        
        return urlRequest
    }
}
