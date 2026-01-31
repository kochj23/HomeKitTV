import SwiftUI
import HomeKit

@main
struct HomeKitTVApp: App {
    @StateObject private var homeManager = HomeKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(homeManager)
                #if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Refresh data when coming to foreground on iPad
                    Task {
                        homeManager.refreshData()
                    }
                }
                #endif
        }
        #if os(iOS)
        .commands {
            // Keyboard shortcuts for iPad
            CommandGroup(after: .newItem) {
                Button("Refresh") {
                    homeManager.refreshData()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        #endif
    }
}
