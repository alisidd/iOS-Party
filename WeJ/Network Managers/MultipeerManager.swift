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
    
    fileprivate var myPeerId: MCPeerID!
    fileprivate var sessions = [MCSession : MCPeerID]()
    var otherHosts = [MCPeerID]()
    fileprivate var isHost: Bool
    private var latestRequest = Data()
    
    weak var delegate : NetworkManagerDelegate?
    
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
        }
    }

    func send(tracks: [Track], toRemove isRemoval: Bool = false) {
        if !sessions.isEmpty {
            let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracks)
            if isRemoval {
                sessions.keys.forEach { try? $0.send(tracksListData, toPeers: $0.connectedPeers, with: .reliable) }
            } else {
                latestRequest = tracksListData
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    guard tracksListData == self?.latestRequest else { return }
                    self?.sessions.keys.forEach { try? $0.send(tracksListData, toPeers: $0.connectedPeers, with: .reliable) }
                }
            }
        }
    }
    
    func sendPartyInfo(toSession session: MCSession) {
        if !sessions.isEmpty && delegate != nil {
            let partyData = NSKeyedArchiver.archivedData(withRootObject: Party())
            try? session.send(partyData, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}

// MARK: - Invitation

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
        print("Received invitation from \(peerID)")
        if sessions.isEmpty {
            let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
            newSession.delegate = self
            sessions[newSession] = peerID
            invitationHandler(true, newSession)
            return
        }
        
        for session in sessions.keys where session.connectedPeers.isEmpty {
            invitationHandler(true, session)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
}

// MARK: - Peer Discovery Callbacks

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer \(peerID)")
        if info?["isHost"] == "true" && !otherHosts.contains(peerID) {
            otherHosts.append(peerID)
        }
        
        if !(isHost == false && info?["isHost"] == "false") {
            let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
            newSession.delegate = self
            
            sessions.forEach { if $0.key.connectedPeers.isEmpty { sessions.removeValue(forKey: $0.key) } }
            let alreadyFound = sessions.contains(where: {$0.key.connectedPeers[0].displayName == peerID.displayName })

            if !alreadyFound {
                sessions[newSession] = peerID
                if isHost {
                    print("Invited \(peerID)")
                    browser.invitePeer(peerID, to: newSession, withContext: nil, timeout: 3)
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost peer \(peerID)")
        if otherHosts.contains(peerID) {
            otherHosts.remove(at: otherHosts.index(of: peerID)!)
        }
        
        for (session, id) in sessions where id == peerID {
            session.disconnect()
            sessions.removeValue(forKey: session)
        }
        
        if !isHost && sessions.isEmpty {
            delegate?.updateStatus(withState: .notConnected)
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

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("State for \(peerID) changed to \(state.stringValue())")
        if !isHost {
            delegate?.updateStatus(withState: state)
        }
        
        if state == .connected && isHost {
            sendPartyInfo(toSession: session)
            send(tracks: Party.tracksQueue)
        } else if state == .notConnected {
            if let index = otherHosts.index(of: peerID) {
                otherHosts.remove(at: index)
            }
            sessions.removeValue(forKey: session)
            if sessions.isEmpty {
                delegate?.resetManager()
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data)
        
        if let party = unarchivedData as? Party {
            delegate?.setup(withParty: party)
        } else if let tracks = unarchivedData as? [Track] {
            if !tracks.isEmpty, case .removal = Track.typeOf(track: tracks[0]) {
                delegate?.remove(track: tracks[0])
            } else {
                delegate?.add(tracksReceived: tracks)
            }
        } else if let position = unarchivedData as? TimeInterval {
            delegate?.update(usingPosition: position)
        }
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        print("Certificate receive")
        certificateHandler(true)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("didReceiveStream")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
}

