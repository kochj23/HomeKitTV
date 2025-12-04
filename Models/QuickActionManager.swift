import Foundation
import HomeKit

class QuickActionManager: ObservableObject {
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