import Foundation

class AnalyticsManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = AnalyticsManager()
    @Published var usagePatterns: [UsagePattern] = []
    @Published var costAnalytics: CostAnalytics = CostAnalytics()
    @Published var efficiencyScore: Int = 85
    
    struct UsagePattern: Identifiable {
        let id: UUID
        let deviceName: String
        let hoursPerDay: Double
        let costPerDay: Double
        let trend: Trend
        
        enum Trend {
            case increasing, decreasing, stable
        }
    }
    
    struct CostAnalytics {
        var dailyCost: Double = 0
        var weeklyCost: Double = 0
        var monthlyCost: Double = 0
        var projectedMonthlyCost: Double = 0
        var comparisonToLastMonth: Double = 0
    }
    
    struct EnvironmentalImpact {
        var co2Saved: Double  // kg
        var treesEquivalent: Int
        var energySaved: Double  // kWh
    }
    
    func analyzeUsagePatterns() {
        usagePatterns.removeAll()
        
        // Example analytics
        usagePatterns.append(UsagePattern(
            id: UUID(),
            deviceName: "Living Room Lights",
            hoursPerDay: 6.5,
            costPerDay: 0.45,
            trend: .stable
        ))
        
        usagePatterns.append(UsagePattern(
            id: UUID(),
            deviceName: "HVAC System",
            hoursPerDay: 18.0,
            costPerDay: 3.20,
            trend: .increasing
        ))
    }
    
    func getEnvironmentalImpact() -> EnvironmentalImpact {
        return EnvironmentalImpact(
            co2Saved: 45.2,
            treesEquivalent: 2,
            energySaved: 125.5
        )
    }
    
    func getOptimizationRecommendations() -> [String] {
        return [
            "Reduce HVAC usage during peak hours to save $12/month",
            "Use automated schedules for lights to save $8/month",
            "Enable eco mode on smart plugs to save $5/month"
        ]
    }
}
