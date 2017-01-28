//
//  NetworkServiceManager.swift
//  Party
//
//  Created by Matthew on 2017-01-20.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//
import Foundation
import MultipeerConnectivity

class NetworkServiceManager: NSObject {
    
    private let MessageServiceType = "localParty"
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    weak var delegate : NetworkManagerDelegate?
    
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
                let tracksData = NSKeyedArchiver.archivedData(withRootObject: Party.idOfTracks(tracks))
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
        for session in sessions {
            print("Connected Peers: \(session.connectedPeers.count)")
            if session.connectedPeers.count == 0 {
                session.disconnect()
                sessions.remove(at: sessions.index(of: session)!)
                print("lostPeer: \(peerID)")
            }
        }
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
        self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map{$0.displayName})
        if session.connectedPeers.count > 0 {
            if state == .connected {
                print("Calling function to send party info")
                self.delegate?.sendPartyInfo(toSession: session)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("didReceiveData: \(data.count) bytes")
        let unarchivedData = NSKeyedUnarchiver.unarchiveObject(with: data)
        if let partyName = unarchivedData as? String {
            self.delegate?.setupParty(withName: partyName)
        } else if let tracksIDList = unarchivedData as? [String] {
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
    
}
