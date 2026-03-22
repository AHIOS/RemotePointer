import AppKit
import SwiftUI

@main
struct RemotePointerMacApp: App {
    @StateObject private var menuBarController = MenuBarController()

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading, spacing: 12) {
                Text("Remote Pointer")
                    .font(.headline)

                HStack(spacing: 8) {
                    Circle()
                        .fill(menuBarController.isConnected ? .green : .orange)
                        .frame(width: 9, height: 9)
                    Text(menuBarController.isConnected ? "Connected to iPhone" : "Waiting for iPhone")
                }
                Text("Peer: \(menuBarController.connectedPeerName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                Text("Permissions")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if menuBarController.cursorController.hasAccessibilityPermission {
                    Text("Accessibility is enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Accessibility is required for pointer control")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Button("Open Accessibility Prompt") {
                        menuBarController.cursorController.requestAccessibilityIfNeeded()
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pointer Sensitivity")
                        .font(.caption)
                    Slider(value: $menuBarController.sensitivity, in: 0.2...3.0, step: 0.1)
                    Text(String(format: "%.1fx", menuBarController.sensitivity))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Divider()
                if menuBarController.isHosting {
                    Button("Stop Hosting") {
                        menuBarController.stopHosting()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Start Hosting") {
                        menuBarController.startHosting()
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let error = menuBarController.lastError {
                    Divider()
                    Text(error)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(3)
                }

                Divider()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(10)
            .frame(width: 260)
            .onAppear {
                menuBarController.startHosting()
            }
        } label: {
            Image(systemName: menuBarController.isConnected ? "dot.radiowaves.left.and.right" : "cursorarrow.rays")
        }
        .menuBarExtraStyle(.window)
    }
}
