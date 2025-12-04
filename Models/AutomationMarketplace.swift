import Foundation

class AutomationMarketplace: ObservableObject {
    static let shared = AutomationMarketplace()
    @Published var templates: [AutomationTemplate] = []
    @Published var installedTemplates: [UUID] = []
    
    struct AutomationTemplate: Identifiable, Codable {
        let id: UUID
        var name: String
        var description: String
        var author: String
        var rating: Double
        var downloadCount: Int
        var category: Category
        var automationData: Data?
        
        enum Category: String, Codable {
            case security, energy, comfort, entertainment, health
        }
    }
    
    init() {
        loadFeaturedTemplates()
    }
    
    func loadFeaturedTemplates() {
        templates = [
            AutomationTemplate(
                id: UUID(),
                name: "Smart Security System",
                description: "Automatically locks doors and arms system when leaving home",
                author: "HomeKit Pro",
                rating: 4.8,
                downloadCount: 15420,
                category: .security
            ),
            AutomationTemplate(
                id: UUID(),
                name: "Energy Optimizer",
                description: "Reduces energy consumption based on occupancy and time",
                author: "GreenHome",
                rating: 4.6,
                downloadCount: 12890,
                category: .energy
            ),
            AutomationTemplate(
                id: UUID(),
                name: "Movie Night",
                description: "Perfect lighting and temperature for movie watching",
                author: "Entertainment Plus",
                rating: 4.9,
                downloadCount: 18750,
                category: .entertainment
            ),
            AutomationTemplate(
                id: UUID(),
                name: "Sleep Routine",
                description: "Optimize environment for better sleep quality",
                author: "SleepWell",
                rating: 4.7,
                downloadCount: 14200,
                category: .health
            )
        ]
    }
    
    func installTemplate(_ template: AutomationTemplate) {
        installedTemplates.append(template.id)
    }
}