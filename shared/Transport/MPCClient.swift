import Foundation
import MultipeerConnectivity
#if canImport(UIKit)
import UIKit
#endif

final class MPCClient: NSObject, ObservableObject {
    @Published private(set) var isBrowsing = false
    @Published private(set) var isConnected = false
    @Published private(set) var connectedPeerName = "None"
    @Published private(set) var lastError: String?

    private let peerID = MCPeerID(displayName: MPCClient.makeDisplayName())
    private lazy var session: MCSession = {
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    private lazy var browser: MCNearbyServiceBrowser = {
        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: TransportConstants.serviceType)
        browser.delegate = self
        return browser
    }()

    private var lastInviteByPeer: [String: Date] = [:]
    private let inviteCooldown: TimeInterval = 3
    private let inviteTimeout: TimeInterval = 20

    func startBrowsing() {
        guard !isBrowsing else { return }
        DispatchQueue.main.async {
            self.isBrowsing = true
        }
        browser.startBrowsingForPeers()
    }

    func stopBrowsing() {
        guard isBrowsing else { return }
        browser.stopBrowsingForPeers()
        session.disconnect()
        DispatchQueue.main.async {
            self.lastInviteByPeer.removeAll()
            self.isBrowsing = false
            self.isConnected = false
            self.connectedPeerName = "None"
        }
    }

    func send(_ message: ControlMessage, mode: MCSessionSendDataMode = .unreliable) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try ControlCodec.encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: mode)
        } catch {
            DispatchQueue.main.async {
                self.lastError = error.localizedDescription
            }
        }
    }
}

private extension MPCClient {
    static func makeDisplayName() -> String {
#if canImport(UIKit)
        UIDevice.current.name
#else
        ProcessInfo.processInfo.hostName
#endif
    }
}

extension MPCClient: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            guard !self.isConnected else { return }
            let now = Date()
            if let lastInvite = self.lastInviteByPeer[peerID.displayName],
               now.timeIntervalSince(lastInvite) < self.inviteCooldown {
                return
            }

            self.lastInviteByPeer[peerID.displayName] = now
            browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: self.inviteTimeout)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.lastInviteByPeer.removeValue(forKey: peerID.displayName)
        }
    }
}

extension MPCClient: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            let connectedPeers = session.connectedPeers
            switch state {
            case .connected:
                self.lastInviteByPeer.removeValue(forKey: peerID.displayName)
            case .connecting:
                if connectedPeers.isEmpty {
                    self.connectedPeerName = "Connecting to \(peerID.displayName)..."
                }
            case .notConnected:
                // Allow immediate retry when connection fails.
                self.lastInviteByPeer.removeValue(forKey: peerID.displayName)
            @unknown default:
                break
            }

            if let firstConnected = connectedPeers.first {
                self.isConnected = true
                self.connectedPeerName = firstConnected.displayName
            } else if state != .connecting {
                self.isConnected = false
                self.connectedPeerName = "None"
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}

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
