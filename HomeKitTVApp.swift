import SwiftUI
import HomeKit

@main
struct HomeKitTVApp: App {
    @StateObject private var homeManager = HomeKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(homeManager)
        }
    }
}
