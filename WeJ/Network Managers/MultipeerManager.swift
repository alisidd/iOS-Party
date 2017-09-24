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
    
    weak var delegate : NetworkManagerDelegate?
    
    private let mssageServiceType = "localParty"
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    fileprivate var myPeerId: MCPeerID!
    
    fileprivate var isHost: Bool
    fileprivate var sessions = [MCSession : MCPeerID]()
    var otherHosts = Set<MCPeerID>()
    private var latestRequest = [Track]()
    static var tracksFailedToSend = [Track]()
    
    // MARK: - Lifecycle
    
    init(isHost: Bool) {
        self.isHost = isHost
        
        let deviceIdentifier = UIDevice.current.identifierForVendor!.uuidString
        let deviceName = UIDevice.current.name
        myPeerId = isHost ? MCPeerID(displayName: deviceName) : MCPeerID(displayName: deviceIdentifier)
        
        if isHost {
            serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: ["isHost": isHost.description], serviceType: mssageServiceType)
        } else {
            serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: mssageServiceType)
        }
        
        super.init()
        
        setDelegates()
        advertise()
    }
    
    deinit {
        if isHost {
            serviceAdvertiser.stopAdvertisingPeer()
        } else {
            serviceBrowser.stopBrowsingForPeers()
        }
    }
    
    private func setDelegates() {
        if isHost {
            serviceAdvertiser.delegate = self
        } else {
            serviceBrowser.delegate = self
        }
    }
    
    func advertise() {
        DispatchQueue.global(qos: .background).async {
            if self.isHost {
                self.serviceAdvertiser.startAdvertisingPeer()
            } else {
                self.serviceBrowser.startBrowsingForPeers()
            }
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
            if !isRemoval {
                latestRequest = tracks
            }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard self != nil && (isRemoval || tracks == self!.latestRequest) else { return }
                
                let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracks)
                self?.sessions.keys.forEach {
                    guard self != nil else { return }
                    if (try? $0.send(tracksListData, toPeers: $0.connectedPeers, with: .reliable)) == nil && !self!.isHost {
                        MultipeerManager.tracksFailedToSend = tracks
                    } else {
                        MultipeerManager.tracksFailedToSend = []
                    }
                }
            }
        } else if !isHost {
            MultipeerManager.tracksFailedToSend = tracks
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
        if !sessions.contains(where: { $0.1 == peerID }) {
            let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
            newSession.delegate = self
            sessions[newSession] = peerID
            invitationHandler(true, newSession)
        } else {
            for session in sessions.keys where session.connectedPeers.isEmpty {
                invitationHandler(true, session)
            }
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer: \(error)")
    }
    
}

// MARK: - Peer Discovery Callbacks

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        otherHosts.update(with: peerID)
        
        let newSession = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        newSession.delegate = self
        
        sessions.forEach { if $0.key.connectedPeers.isEmpty { sessions.removeValue(forKey: $0.key) } }
        let alreadyFound = sessions.contains(where: {$0.key.connectedPeers[0].displayName == peerID.displayName })
        
        if !alreadyFound {
            sessions[newSession] = peerID
            print("Invited \(peerID)")
            browser.invitePeer(peerID, to: newSession, withContext: nil, timeout: 10)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        otherHosts.remove(peerID)
        
        for (session, id) in sessions where id == peerID {
            session.disconnect()
            sessions.removeValue(forKey: session)
        }
        
        if sessions.isEmpty {
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
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("DidFinishReceiving")
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {        
        if state == .connected {
            if isHost {
                sendPartyInfo(toSession: session)
                send(tracks: Party.tracksQueue)
            }
            delegate?.updateStatus(withState: state)
        } else if state == .notConnected {
            if otherHosts.contains(peerID) {
                otherHosts.remove(peerID)
            }
            
            sessions.removeValue(forKey: session)
            if sessions.isEmpty {
                delegate?.updateStatus(withState: state)
                delegate?.resetManager()
            }
        } else {
            delegate?.updateStatus(withState: state)
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
    
    /*
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("didFinishReceivingResourceWithName")
    }*/
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("didStartReceivingResourceWithName")
    }
    
}

