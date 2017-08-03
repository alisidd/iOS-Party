//
//  MultipeerManager.swift
//  WeJ
//
//  Created by Matthew Paletta on 2017-01-20.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MultipeerManager: NSObject {
    // MARK: - General Variables
    
    private let MessageServiceType = "localParty"
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    
    var myPeerId: MCPeerID!
    var sessions = [MCSession : MCPeerID]()
    var otherHosts = [MCPeerID]()
    weak var delegate : NetworkManagerDelegate?
    var isHost: Bool
    
    // MARK: - Lifecycle
    
    init(isHost: Bool) {
        self.isHost = isHost
        
        let UUID = UIDevice.current.identifierForVendor!.uuidString
        let deviceName = UIDevice.current.name
        myPeerId = isHost ? MCPeerID(displayName: deviceName) : MCPeerID(displayName: UUID)
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["isHost": isHost.description], serviceType: MessageServiceType)
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
    
    func advertise() {
        DispatchQueue.global(qos: .background).async {
            self.serviceAdvertiser.startAdvertisingPeer()
            self.serviceBrowser.startBrowsingForPeers()
        }
    }
    
    // MARK: - Functions
    
    func advertise(position: TimeInterval) {
        if !sessions.isEmpty {
            let positionData = NSKeyedArchiver.archivedData(withRootObject: position)
            for session in sessions.keys {
                try? session.send(positionData, toPeers: session.connectedPeers, with: .reliable)
            }
            print("Sending Position")
        }
    }
    
    func send(tracks: [Track]) {
        if !sessions.isEmpty {
            let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracks)
            print("Number of active sessions: \(sessions.count)")
            for session in sessions.keys {
                try? session.send(tracksListData, toPeers: session.connectedPeers, with: .reliable)
            }
            print("Sending Data")
        }
    }
    
    func sendPartyInfo(toSession session: MCSession) {
        if !sessions.isEmpty && delegate != nil {
            let partyData = NSKeyedArchiver.archivedData(withRootObject: Party())
            print("Number of active sessions: \(sessions.count)")
            try? session.send(partyData, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}

// MARK: - Invitation

extension MultipeerManager : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
        
        print("didReceiveInvitationFromPeer \(peerID)")
        
        if sessions.isEmpty {
            let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
            newSession.delegate = self
            sessions[newSession] = peerID
            invitationHandler(true, newSession)
            return
        }
        
        for session in sessions.keys {
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

extension MultipeerManager : MCNearbyServiceBrowserDelegate {
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        if info?["isHost"] == "true" {
            if !otherHosts.contains(peerID) {
                otherHosts.append(peerID)
            }
        }
        
        if !(isHost == false && info?["isHost"] == "false") {
            let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
            newSession.delegate = self
            
            var alreadyFound = false
            for peerInSession in sessions.keys {
                if !peerInSession.connectedPeers.isEmpty {
                    if peerInSession.connectedPeers[0].displayName == peerID.displayName {
                        alreadyFound = true
                    }
                } else {
                    sessions.removeValue(forKey: peerInSession)
                }
            }
            
            if !alreadyFound {
                sessions[newSession] = peerID
                if isHost {
                    print("invitePeer: \(peerID)")
                    browser.invitePeer(peerID, to: newSession, withContext: nil, timeout: 10)
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        if otherHosts.contains(peerID) {
            otherHosts.remove(at: otherHosts.index(of: peerID)!)
        }
        for (session, id) in sessions {
            print("Connected Peers: \(session.connectedPeers.count)")
            if id == peerID {
                session.disconnect()
                sessions.removeValue(forKey: session)
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
        case .notConnected: return "Not Connected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        }
    }
}

// MARK: - Session Callbacks

extension MultipeerManager : MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.stringValue())")
        delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map{$0.displayName})
        if !isHost {
            delegate?.updateStatus(withState: state)
        }
        if state == .connected && isHost {
            sendPartyInfo(toSession: session)
            send(tracks: Party.tracksQueue)
        } else if state == .notConnected {
            if otherHosts.contains(peerID) {
                otherHosts.remove(at: otherHosts.index(of: peerID)!)
            }
            if !isHost {
                sessions.removeValue(forKey: session)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data.count) bytes")
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data)
        if let party = unarchivedData as? Party {
            delegate?.setupParty(withParty: party)
        } else if let tracks = unarchivedData as? [Track], !tracks.isEmpty {
            if case .removal = Track.typeOf(track: tracks[0]) {
                delegate?.remove(track: tracks[0])
            } else {
                delegate?.add(tracksReceived: tracks, fromPeer: peerID)
            }
        } else if let position = unarchivedData as? TimeInterval {
            delegate?.updatePosition(position: position)
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        certificateHandler(true)
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
