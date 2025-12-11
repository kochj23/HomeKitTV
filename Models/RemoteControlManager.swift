import Foundation
import GameController

class RemoteControlManager: ObservableObject {
    static let shared = RemoteControlManager()
    @Published var remoteConnected: Bool = false

    /// Cleans up resources to prevent memory leaks
    ///
    /// **Memory Safety**: CRITICAL - Must remove NotificationCenter observer
    /// Failing to remove observer causes crash when notification fires after dealloc
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setupRemoteControl() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerConnected),
            name: .GCControllerDidConnect,
            object: nil
        )
    }

    @objc func controllerConnected(_ notification: Notification) {
        remoteConnected = true
    }
    
    func handleSwipeGesture(_ direction: SwipeDirection) {
        switch direction {
        }
    }
    
    enum SwipeDirection {
        case up, down, left, right
    }
}