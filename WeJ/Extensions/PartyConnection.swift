//
//  PartyConnection.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension PartyViewController {
    
    func displayAlert() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5) {
            self.alertViewConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func changeStatusIndicatorView(toColor color: UIColor) {
        UIView.animate(withDuration: 0.3) {
            self.statusIndicatorView.backgroundColor = color
        }
    }
    
    func hideAlert(completionHandler: ((Bool) -> Void)? = nil) {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 1, animations: {
            self.alertViewConstraint.constant = -50
            self.view.layoutIfNeeded()
        }, completion: completionHandler)
    }
    
    func showConnectionRelatedViewsOnAlert() {
        reconnectButton.isHidden = false
        statusIndicatorView.isHidden = false
        resendButton.isHidden = true
    }
    
    func hideConnectionRelatedViewsOnAlert() {
        reconnectButton.isHidden = true
        statusIndicatorView.isHidden = true
    }
    
}
