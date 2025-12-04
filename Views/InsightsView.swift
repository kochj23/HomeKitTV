import SwiftUI
import HomeKit

/// Insights and predictive intelligence view
struct InsightsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var predictiveEngine = PredictiveEngine.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Insights")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Button(action: {
                            predictiveEngine.analyzePatterns()
                            predictiveEngine.generateSuggestions(homeManager: homeManager)
                            predictiveEngine.detectAnomalies(homeManager: homeManager)
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Analyze")
                            }
                            .font(.title3)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    // Smart Suggestions
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Smart Suggestions")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        if predictiveEngine.suggestions.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No suggestions yet")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                Text("Tap 'Analyze' to generate smart suggestions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(predictiveEngine.suggestions) { suggestion in
                                    SuggestionCard(suggestion: suggestion)
                                }
                            }
                            .padding(.horizontal, 80)
                        }
                    }

                    // Usage Patterns
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Usage Patterns")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        if predictiveEngine.usagePatterns.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No patterns detected")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(predictiveEngine.usagePatterns) { pattern in
                                    PatternCard(pattern: pattern)
                                }
                            }
                            .padding(.horizontal, 80)
                        }
                    }

                    // Anomalies
                    if !predictiveEngine.anomalies.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Anomalies Detected")
                                .font(.title2)
                                .padding(.horizontal, 80)

                            VStack(spacing: 15) {
                                ForEach(predictiveEngine.anomalies) { anomaly in
                                    AnomalyCard(anomaly: anomaly)
                                }
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            predictiveEngine.generateSuggestions(homeManager: homeManager)
            predictiveEngine.detectAnomalies(homeManager: homeManager)
        }
    }
}

/// Smart suggestion card
struct SuggestionCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var predictiveEngine = PredictiveEngine.shared
    let suggestion: SmartSuggestion

    var priorityColor: Color {
        switch suggestion.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }

    var iconName: String {
        switch suggestion.type {
        case .createAutomation: return "gearshape.2.fill"
        case .createScene: return "sparkles"
        case .addToFavorites: return "star.fill"
        case .energySaving: return "leaf.fill"
        case .createServiceGroup: return "square.stack.3d.up.fill"
        case .optimizeSchedule: return "clock.arrow.circlepath"
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(priorityColor)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(suggestion.title)
                    .font(.title3)
                    .bold()

                Text(suggestion.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                    Text("\(suggestion.priority == .high ? "High" : suggestion.priority == .medium ? "Medium" : "Low") Priority")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 15) {
                Button(action: {
                    // Apply suggestion
                    applySuggestion(suggestion)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                Button(action: {
                    predictiveEngine.dismissSuggestion(suggestion)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(25)
        .background(priorityColor.opacity(0.05))
        .cornerRadius(15)
    }

    private func applySuggestion(_ suggestion: SmartSuggestion) {
        switch suggestion.type {
        case .addToFavorites:
            if let accessoryID = suggestion.metadata["accessory_id"],
               let accessory = homeManager.accessories.first(where: { $0.uniqueIdentifier.uuidString == accessoryID }) {
                Settings.shared.toggleFavorite(accessory)
                homeManager.statusMessage = "Added \(accessory.name) to favorites"
            }

        case .createScene:
            homeManager.createScene(name: "Suggested Scene") { _, error in
                if error == nil {
                    homeManager.statusMessage = "Scene created! Edit it to add accessories."
                }
            }

        case .createServiceGroup:
            let lights = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLightbulb } }
            let lightIDs = Set(lights.map { $0.uniqueIdentifier.uuidString })
            ServiceGroupManager.shared.createGroup(name: "All Lights", icon: "lightbulb.fill", color: "yellow", accessoryIDs: lightIDs)
            homeManager.statusMessage = "Created 'All Lights' group"

        default:
            homeManager.statusMessage = "Suggestion applied"
        }

        predictiveEngine.dismissSuggestion(suggestion)
    }
}

/// Usage pattern card
struct PatternCard: View {
    let pattern: UsagePattern

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 35))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(pattern.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)

                Text(pattern.description)
                    .font(.title3)

                HStack(spacing: 8) {
                    Text("Confidence: \(Int(pattern.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(pattern.detectedAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(20)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
}

/// Anomaly card
struct AnomalyCard: View {
    let anomaly: Anomaly

    var severityColor: Color {
        switch anomaly.severity {
        case .info: return .blue
        case .warning: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }

    var iconName: String {
        switch anomaly.type {
        case .deviceUnreachable: return "wifi.slash"
        case .lowBattery: return "battery.0"
        case .unusualActivity: return "exclamationmark.triangle.fill"
        case .energySpike: return "bolt.fill"
        case .securityBreach: return "lock.open.fill"
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(severityColor)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(severityColor)
                        .frame(width: 10, height: 10)
                    Text(anomaly.severity == .high ? "High Severity" : anomaly.severity == .critical ? "Critical" : anomaly.severity == .warning ? "Warning" : "Info")
                        .font(.caption)
                        .foregroundColor(severityColor)
                        .bold()
                }

                Text(anomaly.description)
                    .font(.title3)

                if !anomaly.affectedDevices.isEmpty {
                    Text("Affected: \(anomaly.affectedDevices.prefix(3).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Text(anomaly.detectedAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                // Handle anomaly
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 25))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(25)
        .background(severityColor.opacity(0.1))
        .cornerRadius(15)
    }
}

#Preview {
    InsightsView()
        .environmentObject(HomeKitManager())
}
