//
//  NetworkServiceManager.swift
//  Party
//
//  Created by Matthew on 2017-01-20.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit
import Foundation
import MultipeerConnectivity

protocol NetworkManagerDelegate {
    func connectedDevicesChanged(_ manager : NetworkServiceManager, connectedDevices: [String])
    func messageChanged(_ manager : NetworkServiceManager, messageString: String)
}


class NetworkServiceManager: NSObject {
    
    fileprivate let MessageServiceType = "localParty"
    fileprivate let serviceAdvertiser : MCNearbyServiceAdvertiser
    fileprivate let serviceBrowser : MCNearbyServiceBrowser
    var delegate : NetworkManagerDelegate?
    
    var myPeerId: MCPeerID!
    var partyName: String?
    
    override init() {
        
        // Broadcast as the party name or the device name if not applicable
        myPeerId = MCPeerID(displayName: partyName ?? UIDevice.current.name)
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: MessageServiceType)
        
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: MessageServiceType)
        
        super.init()
        
        DispatchQueue.global(qos: .background).async {
            self.serviceAdvertiser.delegate = self
            self.serviceAdvertiser.startAdvertisingPeer()
            
            self.serviceBrowser.delegate = self
            self.serviceBrowser.startBrowsingForPeers()
        }
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        session.delegate = self
        return session
    }()
    
    func sendMessage(_ messageData : String) {
        print("sendMessage: \(messageData)")
        
        if session.connectedPeers.count > 0 {
            do {
                let result = try self.session.send(messageData.data(using: String.Encoding.utf8, allowLossyConversion: false)!, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable) as Any
                print(result)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        
    }
    
}

extension NetworkServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
        
        print("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}

extension NetworkServiceManager : MCNearbyServiceBrowserDelegate {
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        print("invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lostPeer: \(peerID)")
    }
    
}

extension MCSessionState {
    
    func stringValue() -> String {
        switch self {
        case .notConnected: return "NotConnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        }
    }
    
}

extension NetworkServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.stringValue())")
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data.count) bytes")
        let str = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
        self.delegate?.messageChanged(self, messageString: str)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
}
