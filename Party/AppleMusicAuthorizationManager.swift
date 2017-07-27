//
//  AppleMusicAuthorizationManager.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/26/17.
//  Copyright © 2017 Ali Siddiqui. All rights reserved.
//

import Foundation
import StoreKit

protocol AuthorizationManager {
    var isAuthorized: Bool { get set }
    func requestAuthorization()
}

class AppleMusicAuthorizationManager: AuthorizationManager {
    static weak var delegate: ViewControllerAccessDelegate!
    
    static let cloudServiceController = SKCloudServiceController()
    var isAuthorized = SKCloudServiceController.authorizationStatus() == .authorized
    static var storefrontIdentifier = String()
    
    func requestAuthorization() {
        AppleMusicAuthorizationManager.delegate.processingLogin = true
        if isAuthorized {
            AppleMusicAuthorizationManager.requestStorefrontIdentifier()
        } else {
            SKCloudServiceController.requestAuthorization { (status) in
                self.isAuthorized = status == .authorized
                AppleMusicAuthorizationManager.requestStorefrontIdentifier()
            }
        }
    }
    
    static func requestStorefrontIdentifier() {
        cloudServiceController.requestStorefrontIdentifier { (storefrontId, _) in
            if let storefrontId = storefrontId, storefrontId.characters.count >= 6 {
                let range = storefrontId.startIndex...storefrontId.index(storefrontId.startIndex, offsetBy: 5)
                storefrontIdentifier = String(storefrontId[range])
                print(storefrontIdentifier)
            }
            delegate.processingLogin = false
        }
    }
}
