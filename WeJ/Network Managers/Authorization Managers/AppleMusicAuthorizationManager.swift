//
//  AppleMusicAuthorizationManager.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/26/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import StoreKit

protocol AuthorizationManager {
    var isAuthorized: Bool { get set }
    func requestAuthorization()
}

class AppleMusicAuthorizationManager: AuthorizationManager {
    static weak var delegate: ViewControllerAccessDelegate?
    
    static let cloudServiceController = SKCloudServiceController()
    var isAuthorized = SKCloudServiceController.authorizationStatus() == .authorized
    
    func requestAuthorization() {
        AppleMusicAuthorizationManager.delegate?.processingLogin = true
        if isAuthorized {
            AppleMusicAuthorizationManager.requestStorefrontIdentifier()
        } else {
            SKCloudServiceController.requestAuthorization { [weak self] (status) in
                self?.isAuthorized = status == .authorized
                AppleMusicAuthorizationManager.requestStorefrontIdentifier()
            }
        }
    }
    
    static func requestStorefrontIdentifier() {
        cloudServiceController.requestStorefrontIdentifier { (storefrontId, _) in
            if let storefrontId = storefrontId?.components(separatedBy: "-").first {
                Party.cookie = AppleMusicConstants.countryCodes[storefrontId]
                delegate?.processingLogin = false
            }
        }
    }
}
