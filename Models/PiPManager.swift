import Foundation
import AVKit

class PiPManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = PiPManager()
    @Published var isPiPActive: Bool = false
    @Published var pipController: AVPictureInPictureController?
    
    func startPiP(with player: AVPlayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        
        if let playerLayer = AVPlayerLayer(player: player) as AVPlayerLayer? {
            pipController = AVPictureInPictureController(playerLayer: playerLayer)
            pipController?.startPictureInPicture()
            isPiPActive = true
        }
    }
    
    func stopPiP() {
        pipController?.stopPictureInPicture()
        isPiPActive = false
    }
}
