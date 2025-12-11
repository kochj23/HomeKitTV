import Foundation
import HomeKit

class QuickActionManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = QuickActionManager()
    @Published var quickActions: [QuickAction] = []
    
    struct QuickAction: Identifiable, Codable {
        let id: UUID
        var name: String
        var deviceID: String
        var action: String
        var icon: String
    }
    
    func addQuickAction(_ action: QuickAction) {
        quickActions.append(action)
    }
}
