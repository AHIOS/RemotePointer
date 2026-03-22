import Foundation

@MainActor
final class MenuBarController: ObservableObject {
    @Published private(set) var isHosting = false
    @Published private(set) var isConnected = false
    @Published private(set) var connectedPeerName = "None"
    @Published private(set) var lastError: String?
    @Published var sensitivity: Double = 1.0 {
        didSet {
            cursorController.macSensitivity = sensitivity
        }
    }

    let cursorController = CursorController()
    private let host = MPCHost()
    private var permissionPollTimer: Timer?

    init() {
        host.onMessage = { [weak self] message in
            self?.handle(message: message)
        }
        host.onStateChange = { [weak self] in
            self?.refreshStatus()
        }
    }

    func refreshStatus() {
        cursorController.refreshPermissionStatus()
        isHosting = host.isHosting
        isConnected = host.isConnected
        connectedPeerName = host.connectedPeerName
        lastError = host.lastError
    }

    func startHosting() {
        cursorController.requestAccessibilityIfNeeded()
        host.startHosting()
        startPermissionPolling()
        refreshStatus()
    }

    func stopHosting() {
        host.stopHosting()
        stopPermissionPolling()
        refreshStatus()
    }

    private func handle(message: ControlMessage) {
        switch message {
        case let .move(deltaX, deltaY, _):
            cursorController.apply(deltaX: deltaX, deltaY: deltaY)
        case let .click(button):
            cursorController.click(button: button)
        case let .setSensitivity(value):
            sensitivity = value
        case .keyboardText, .keyboardKey, .ping:
            break
        }
        refreshStatus()
    }

    private func startPermissionPolling() {
        guard permissionPollTimer == nil else { return }
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.refreshStatus()
        }
    }

    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    deinit {
        permissionPollTimer?.invalidate()
    }
}
