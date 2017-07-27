//
//  PartyConnection.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/27/17.
//  Copyright © 2017 Ali Siddiqui. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension PartyViewController {
    var connectionStatus: MCSessionState {
        get {
            return self.connectionStatus
        }
        set {
            DispatchQueue.main.async {
                self.displayStatusLabel()
                self.connectionStatusLabel.text = newValue.stringValue()
                
                if newValue == .connected {
                    self.removeReconnectButton()
                    self.removeStatusLabel()
                } else if newValue == .connecting {
                    self.displayReconnectButton()
                    //TODO: set a reconnect timer
                    self.lyricsAndQueueVC.expandTracksTable()
                } else {
                    self.displayReconnectButton()
                    self.lyricsAndQueueVC.expandTracksTable()
                }
            }
        }
    }
    
    func displayStatusLabel() {
        UIView.animate(withDuration: 0.5) {
            self.connectionStatusLabel.isHidden = false
            self.connectionStatusLabel.alpha = 1
        }
    }
    
    func removeStatusLabel() {
        UIView.animate(withDuration: 1, animations: {
            self.connectionStatusLabel.alpha = 0
        }, completion: { (finished) in
            self.connectionStatusLabel.isHidden = true
        })
    }
    
    func displayReconnectButton() {
        view.layoutIfNeeded()
        reconnectButton.isHidden = false
        UIView.animate(withDuration: 0.4) {
            self.reconnectButton.alpha = 1
            self.view.layoutIfNeeded()
        }
    }
    
    func removeReconnectButton() {
        view.layoutIfNeeded()
        reconnectButton.isHidden = true
        UIView.animate(withDuration: 0.4) {
            self.reconnectButton.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}
