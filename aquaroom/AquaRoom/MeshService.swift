import Foundation
import MultipeerConnectivity

/// Bluetooth / Wi-Fi のローカル通信（MultipeerConnectivity）。サーバー不要。
final class MeshService: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    private let peerID = MCPeerID(displayName: "fish-" + String(UUID().uuidString.prefix(8)))
    private lazy var session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    private lazy var advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "aquaroom")
    private lazy var browser = MCNearbyServiceBrowser(peer: peerID, serviceType: "aquaroom")

    var onPacket: ((Packet) -> Void)?
    var onPeersChanged: ((Int) -> Void)?
    var onPeerJoined: (() -> Void)?

    func start() {
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()
    }

    func send(_ packet: Packet) {
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(packet) else { return }
        try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }

    // 双方が同時に招待し合わないよう、名前が小さい側だけが招待する
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peer: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        if peerID.displayName < peer.displayName {
            browser.invitePeer(peer, to: session, withContext: nil, timeout: 15)
        }
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peer: MCPeerID) {}

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let count = session.connectedPeers.count
        DispatchQueue.main.async {
            self.onPeersChanged?(count)
            if state == .connected { self.onPeerJoined?() }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let packet = try? JSONDecoder().decode(Packet.self, from: data) else { return }
        DispatchQueue.main.async { self.onPacket?(packet) }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
