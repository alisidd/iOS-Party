//
//  PartyConnection.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import MultipeerConnectivity

fileprivate let red = UIColor(red: 255/255, green: 71/255, blue: 62/255, alpha: 1)
fileprivate let orange = UIColor(red: 255/255, green: 166/255, blue: 35/255, alpha: 1)
fileprivate let green = UIColor(red: 117/255, green: 203/255, blue: 39/255, alpha: 1)

extension PartyViewController {
    var connectionStatus: MCSessionState {
        get {
            return self.connectionStatus
        }
        set {
            DispatchQueue.main.async {
                self.displayStatusView()
                self.connectionStatusLabel.text = newValue.stringValue()
                
                if newValue == .connected {
                    self.changeStatusIndicatorView(toColor: green)
                    self.hideStatusView()
                    self.hubAndQueueVC.showAddButton()
                } else if newValue == .connecting {
                    self.changeStatusIndicatorView(toColor: orange)
                } else {
                    self.changeStatusIndicatorView(toColor: red)
                    self.hubAndQueueVC.hideAddButton()
                }
            }
        }
    }
    
    func displayStatusView() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5) {
            self.connectionStatusViewConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func changeStatusIndicatorView(toColor color: UIColor) {
        UIView.animate(withDuration: 0.3) {
            self.statusIndicatorView.backgroundColor = color
        }
    }
    
    func hideStatusView() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 1) {
            self.connectionStatusViewConstraint.constant = -50
            self.view.layoutIfNeeded()
        }
    }
}
