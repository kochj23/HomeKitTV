import Foundation

class IntegrationHubExpanded: ObservableObject {
    static let shared = IntegrationHubExpanded()
    @Published var integrations: [Integration] = []
    
    struct Integration: Identifiable {
        let id: UUID
        let name: String
        let type: IntegrationType
        var isEnabled: Bool
        var configuration: [String: String]
    }
    
    enum IntegrationType {
        case weather, calendar, music, security, smartAppliances, evCharging
    }
    
    func enableIntegration(_ type: IntegrationType, config: [String: String]) {
        let integration = Integration(
            id: UUID(),
            name: type.description,
            type: type,
            isEnabled: true,
            configuration: config
        )
        integrations.append(integration)
    }
}

extension IntegrationHubExpanded.IntegrationType: CustomStringConvertible {
    var description: String {
        switch self {
        case .weather: return "Weather"
        case .calendar: return "Calendar"
        case .music: return "Music"
        case .security: return "Security"
        case .smartAppliances: return "Smart Appliances"
        case .evCharging: return "EV Charging"
        }
    }
}