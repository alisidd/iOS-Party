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
    var sessions = [MCSession : MCPeerID]()
    weak var delegate : NetworkManagerDelegate?
    
    // MARK: - Lifecycle
    
    init(_ isHost: Bool) {
        let UUID = UIDevice.current.identifierForVendor!.uuidString
        
        // Broadcast as the party name or the device name if not applicable
        myPeerId = MCPeerID(displayName: UUID)
        
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
    
    func advertise() {
        DispatchQueue.global(qos: .background).async {
            self.serviceAdvertiser.startAdvertisingPeer()
            self.serviceBrowser.startBrowsingForPeers()
        }
    }
    
    // MARK: - Functions
    
    func sendTracks(_ tracksList: [String]) {
        if sessions.count > 0 {
            do {
                let tracksListData = NSKeyedArchiver.archivedData(withRootObject: tracksList)
                print("Number of active sessions: \(sessions.count)")
                for session in sessions.keys {
                    try session.send(tracksListData, toPeers: session.connectedPeers, with: .reliable)
                }
                print("Sending Data")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func sendPartyInfo(withTracks tracks: [Track], forService service: MusicService, toSession session: MCSession) {
        if sessions.count > 0 {
            do {
                let tracksData = NSKeyedArchiver.archivedData(withRootObject: id(ofTracks: tracks, forService: service))
                let serviceToSend = service == .spotify ? "s" : "a"
                let musicServiceData = NSKeyedArchiver.archivedData(withRootObject: serviceToSend)
                print("Number of active sessions: \(sessions.count)")
                try session.send(tracksData, toPeers: session.connectedPeers, with: .reliable)
                try session.send(musicServiceData, toPeers: session.connectedPeers, with: .reliable)
                print("Sending Party info to other device")
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
    
    func id(ofTracks tracks: [Track], forService service: MusicService) -> [String] {
        var result = [String]()
        for track in tracks {
            if service == .spotify {
                result.append(track.id)
            } else {
                result.append(track.id + "-" + track.artist)
            }
        }
        return result
    }
}

// MARK: - Invitation

extension NetworkServiceManager : MCNearbyServiceAdvertiserDelegate {
    
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

extension NetworkServiceManager : MCNearbyServiceBrowserDelegate {
    
    @available(iOS 7.0, *)
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("foundPeer: \(peerID)")
        if !(delegate!.amHost() == false && info?["isHost"] == "false") {
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
                if delegate!.amHost() {
                    print("invitePeer: \(peerID)")
                    browser.invitePeer(peerID, to: newSession, withContext: nil, timeout: 10)
                }
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
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

extension NetworkServiceManager : MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer \(peerID) didChangeState: \(state.stringValue())")
        delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map{$0.displayName})
        if !delegate!.amHost() {
            delegate?.updateStatus(with: state)
        }
        if state == .connected {
            print("Calling function to send party info")
            delegate?.sendPartyInfo(toSession: session)
        } else if state == .notConnected {
            if !delegate!.amHost() {
               sessions.removeValue(forKey: session)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data.count) bytes")
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data)
        if let musicService = unarchivedData as? String {
            delegate?.setupParty(withService: musicService)
        } else if var tracksIDList = unarchivedData as? [String] {
            if !tracksIDList.isEmpty {
                if tracksIDList[0].contains(":/?r") {
                    delegate?.removeTrackFromPeer(withTrack: tracksIDList[0])
                    return
                }
            }
            delegate?.addTracks(fromPeer: peerID, withTracks: tracksIDList)
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
