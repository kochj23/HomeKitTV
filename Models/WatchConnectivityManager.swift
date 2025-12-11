import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    @Published var isWatchConnected: Bool = false
    
    private var session: WCSession?
    
    override private init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    /// Cleans up resources to prevent memory leaks
    ///
    /// **Memory Safety**: Clears delegate to break retain cycle with WCSession
    deinit {
        session?.delegate = nil
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        isWatchConnected = activationState == .activated
    }
    
    func sendToWatch(_ data: [String: Any]) {
        session?.sendMessage(data, replyHandler: nil)
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    #endif
}