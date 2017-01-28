//
//  NetworkServiceManager.swift
//  Party
//
//  Created by Matthew on 2017-01-20.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//
/*
import Foundation
import MultipeerConnectivity

protocol NetworkManagerDelegate {
    func connectedDevicesChanged(_ manager : NetworkServiceManager, connectedDevices: [String])
    func addTracksFromPeer(withTracks tracks: [String])
}

class NetworkServiceManager: NSObject {
    
    private let MessageServiceType = "localParty"
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    var delegate : NetworkManagerDelegate?
    
    var myPeerId: MCPeerID!
    var partyName: String?
    var sessions = [MCSession]()
    
    override init() {
        // Broadcast as the party name or the device name if not applicable
        myPeerId = MCPeerID(displayName: partyName ?? UIDevice.current.name)
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: MessageServiceType)
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: MessageServiceType)
        
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
    
    func sendTracks(_ tracksList: [String]) {
        if sessions.count > 0 {
            do {
                let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracksList)
                for session in sessions {
                    try session.send(tracksListData, toPeers: session.connectedPeers, with: .reliable)
                }
                print("SENDING DATA")
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
        
        for session in sessions {
            if session.connectedPeers.isEmpty {
                invitationHandler(true, session)
            }
        }
    }
}

extension NetworkServiceManager : MCNearbyServiceBrowserDelegate {
    
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        print("invitePeer: \(peerID)")
        let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        newSession.delegate = self
        sessions.append(newSession)
        browser.invitePeer(peerID, to: newSession, withContext: nil, timeout: 10)
        
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
        
        if let tracksIDList = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String] {
            print("didReceiveData: \(data.count) bytes")
            self.delegate?.addTracksFromPeer(withTracks: tracksIDList)
        }
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
    
}*/
