import SwiftUI

@main
struct RemotePointeriOSApp: App {
    @StateObject private var client = MPCClient()

    var body: some Scene {
        WindowGroup {
            ControllerView(client: client)
                .onAppear {
                    client.startBrowsing()
                }
                .onDisappear {
                    client.stopBrowsing()
                }
        }
    }
}
