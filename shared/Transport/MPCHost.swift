import Foundation
import MultipeerConnectivity

final class MPCHost: NSObject, ObservableObject {
    @Published private(set) var isHosting = false
    @Published private(set) var isConnected = false
    @Published private(set) var connectedPeerName = "None"
    @Published private(set) var lastError: String?

    var onMessage: ((ControlMessage) -> Void)?
    var onStateChange: (() -> Void)?

    private let peerID = MCPeerID(displayName: ProcessInfo.processInfo.hostName)
    private lazy var session: MCSession = {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    private lazy var advertiser: MCNearbyServiceAdvertiser = {
        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: TransportConstants.discoveryInfo,
            serviceType: TransportConstants.serviceType
        )
        advertiser.delegate = self
        return advertiser
    }()

    func startHosting() {
        guard !isHosting else { return }
        DispatchQueue.main.async {
            self.isHosting = true
            self.onStateChange?()
        }
        advertiser.startAdvertisingPeer()
    }

    func stopHosting() {
        guard isHosting else { return }
        advertiser.stopAdvertisingPeer()
        session.disconnect()
        DispatchQueue.main.async {
            self.isHosting = false
            self.isConnected = false
            self.connectedPeerName = "None"
            self.onStateChange?()
        }
    }

    func send(_ message: ControlMessage, mode: MCSessionSendDataMode = .reliable) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try ControlCodec.encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: mode)
        } catch {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
                self.onStateChange?()
            }
        }
    }
}

extension MPCHost: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        invitationHandler(true, self.session)
    }
}

extension MPCHost: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            self.isConnected = state == .connected
            self.connectedPeerName = state == .connected ? peerID.displayName : "None"
            self.onStateChange?()
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            do {
                let message = try ControlCodec.decode(data)
                self.onMessage?(message)
            } catch {
                self.lastError = error.localizedDescription
                self.onStateChange?()
            }
        }
    }

    nonisolated func session(
        _ session: MCSession,
        didReceive stream: InputStream,
        withName streamName: String,
        fromPeer peerID: MCPeerID
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        with progress: Progress
    ) {}

    nonisolated func session(
        _ session: MCSession,
        didFinishReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID,
        at localURL: URL?,
        withError error: Error?
    ) {}
}
