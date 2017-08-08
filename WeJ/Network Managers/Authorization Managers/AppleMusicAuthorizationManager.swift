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
    func requestAuthorization()
}

class AppleMusicAuthorizationManager: AuthorizationManager {
    static weak var delegate: ViewControllerAccessDelegate?
    
    static let cloudServiceController = SKCloudServiceController()
    
    func requestAuthorization() {
        AppleMusicAuthorizationManager.delegate?.processingLogin = true
        if SKCloudServiceController.authorizationStatus() == .authorized {
            AppleMusicAuthorizationManager.requestStorefrontIdentifier()
        } else {
            SKCloudServiceController.requestAuthorization { (status) in
                if status == .authorized {
                    AppleMusicAuthorizationManager.requestStorefrontIdentifier()
                } else {
                    AppleMusicAuthorizationManager.postAlertForSettings()
                }
            }
        }
    }
    
    static func requestStorefrontIdentifier() {
        let countryCodeHandler: (String?, Error?) -> Void = { (countryCode, error) in
            if let storefrontId = countryCode?.components(separatedBy: "-").first,
                let countryCode = AppleMusicConstants.countryCodes[storefrontId] ?? countryCode {
                Party.cookie = countryCode
                DispatchQueue.main.async {
                    delegate?.performSegue(withIdentifier: "Create Party", sender: nil)
                }
            } else {
                postAlertForInternet()
            }
            delegate?.processingLogin = false
        }
        
        if #available(iOS 11.0, *) {
            //cloudServiceController.requestStorefrontCountryCode(completionHandler: countryCodeHandler)
        } else {
            cloudServiceController.requestStorefrontIdentifier(completionHandler: countryCodeHandler)
        }
    }
    
    private static func postAlertForSettings() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Apple Music Access Denied", message: "Go to Settings to enable Apple Music", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            })
            
            delegate?.present(alert, animated: true, completion: nil)
        }
    }
    
    private static func postAlertForInternet() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Please check your internet connection", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
                delegate?.createParty()
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            delegate?.present(alert, animated: true, completion: nil)
        }
    }
}
