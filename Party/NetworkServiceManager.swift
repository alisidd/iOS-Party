//
//  NetworkServiceManager.swift
//  Party
//
//  Created by Matthew on 2017-01-20.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class NetworkServiceManager: NSObject {
    
    // MARK: - General Variables
    
    private let MessageServiceType = "localParty"
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var myPeerId: MCPeerID!
    var partyName = String()
    var sessions = [MCSession]()
    weak var delegate : NetworkManagerDelegate?
    
    // MARK: - Lifecycle
    
    init(_ isHost: Bool) {
        // Broadcast as the party name or the device name if not applicable
        myPeerId = MCPeerID(displayName: !partyName.isEmpty ? partyName : UIDevice.current.name)
        
        let infoAboutHost = ["isHost": isHost.description]
        print("Delegate info: \(isHost)")
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: infoAboutHost, serviceType: MessageServiceType)
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
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        print("Destroying Network Manager")
    }
    
    // MARK: - Functions
    
    func sendTracks(_ tracksList: [String]) {
        if sessions.count > 0 {
            do {
                let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracksList)
                print("Number of active sessions: \(sessions.count)")
                for session in sessions {
                    try session.send(tracksListData, toPeers: session.connectedPeers, with: .reliable)
                }
                print("Sending Data")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func sendPartyInfo(withTracks tracks: [Track], withName name: String, toSession session: MCSession) {
        if sessions.count > 0 {
            do {
                let tracksData = NSKeyedArchiver.archivedData(withRootObject: Track.idOfTracks(tracks))
                let partyNameData = NSKeyedArchiver.archivedData(withRootObject: name)
                print("Number of active sessions: \(sessions.count)")
                try session.send(tracksData, toPeers: session.connectedPeers, with: .reliable)
                try session.send(partyNameData, toPeers: session.connectedPeers, with: .reliable)
                print("Sending Party info to other device")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - Invitation

extension NetworkServiceManager : MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
        
        print("didReceiveInvitationFromPeer \(peerID)")
        
        for session in sessions {
            if session.connectedPeers.isEmpty {
                invitationHandler(true, session)
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
      
}

// MARK: - Peer Discovery Callbacks

extension NetworkServiceManager : MCNearbyServiceBrowserDelegate {
    
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        if !(delegate?.amHost() == false && info?["isHost"] == "false") {
            let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
            newSession.delegate = self
            
            var alreadyFound = false
            for session in sessions {
                // improve: make sure peerid display name is different for very user
                if session.myPeerID.displayName == peerID.displayName {
                    alreadyFound = true
                }
            }
            if !alreadyFound {
                sessions.append(newSession)
            }
            print("invitePeer: \(peerID)")
            browser.invitePeer(peerID, to: newSession, withContext: nil, timeout: 10)
        }
        
        
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        for session in sessions {
            print("Connected Peers: \(session.connectedPeers.count)")
            if session.connectedPeers.count == 0 {
                session.disconnect()
                sessions.remove(at: sessions.index(of: session)!)
                print("lostPeer: \(peerID)")
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("didNotStartBrowsingForPeers: \(error)")
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

// MARK: - Session Callbacks

extension NetworkServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.stringValue())")
        delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map{$0.displayName})
        if session.connectedPeers.count > 0 {
            if state == .connected {
                print("Calling function to send party info")
                delegate?.sendPartyInfo(toSession: session)
            } else if state == .notConnected {
                sessions.remove(at: sessions.index(of: session)!)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data.count) bytes")
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data)
        if let partyName = unarchivedData as? String {
            delegate?.setupParty(withName: partyName)
        } else if let tracksIDList = unarchivedData as? [String] {
            delegate?.addTracksFromPeer(withTracks: tracksIDList)
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
    
}
