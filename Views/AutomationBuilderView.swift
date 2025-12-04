import SwiftUI
import HomeKit

/// Visual automation builder with conditions
///
/// Features:
/// - If/Then/Else logic
/// - Multiple conditions
/// - Time-based triggers
/// - Sensor-based triggers
/// - Multi-step actions
struct AutomationBuilderView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var builder = AutomationBuilder.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Automation Builder")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Button(action: {
                            builder.createNewAutomation()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("New")
                            }
                            .font(.title3)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    if builder.customAutomations.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "flowchart.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Custom Automations")
                                .font(.title2)
                            Text("Build advanced automations with conditions")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(builder.customAutomations) { automation in
                                NavigationLink(destination: EditAutomationView(automation: automation)) {
                                    CustomAutomationRow(automation: automation)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// Custom automation row
struct CustomAutomationRow: View {
    let automation: CustomAutomation

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "flowchart.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(automation.name)
                    .font(.title3)
                    .bold()

                HStack(spacing: 12) {
                    Label("\(automation.conditions.count) conditions", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)

                    Label("\(automation.thenActions.count) actions", systemImage: "bolt")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(6)
                }
            }

            Spacer()

            Toggle("", isOn: .constant(automation.enabled))
                .labelsHidden()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Edit automation view
struct EditAutomationView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let automation: CustomAutomation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text(automation.name)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                // IF Section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("IF (Conditions)")
                            .font(.title2)
                            .foregroundColor(.blue)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    if automation.conditions.isEmpty {
                        Text("No conditions yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(30)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                    } else {
                        ForEach(automation.conditions) { condition in
                            ConditionCard(condition: condition)
                        }
                    }
                }
                .padding(.horizontal, 80)

                // THEN Section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("THEN (Actions)")
                            .font(.title2)
                            .foregroundColor(.green)

                        Spacer()

                        Button(action: {}) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.green)
                        }
                        .buttonStyle(.plain)
                    }

                    if automation.thenActions.isEmpty {
                        Text("No actions yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(30)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(12)
                    } else {
                        ForEach(automation.thenActions) { action in
                            ActionCard(action: action)
                        }
                    }
                }
                .padding(.horizontal, 80)

                // ELSE Section (optional)
                if !automation.elseActions.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("ELSE (Alternative Actions)")
                                .font(.title2)
                                .foregroundColor(.orange)

                            Spacer()

                            Button(action: {}) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.orange)
                            }
                            .buttonStyle(.plain)
                        }

                        ForEach(automation.elseActions) { action in
                            ActionCard(action: action)
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
            .padding(.bottom, 60)
        }
    }
}

/// Condition card
struct ConditionCard: View {
    let condition: AutomationCondition

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconForCondition)
                .font(.system(size: 30))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(condition.description)
                    .font(.body)

                Text(condition.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }

    var iconForCondition: String {
        switch condition.type {
        case .time: return "clock.fill"
        case .temperature: return "thermometer"
        case .humidity: return "humidity.fill"
        case .motion: return "figure.walk"
        case .doorOpen: return "door.left.hand.open"
        case .accessoryState: return "power"
        }
    }
}

/// Action card
struct ActionCard: View {
    let action: AutomationAction

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconForAction)
                .font(.system(size: 30))
                .foregroundColor(.green)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(action.description)
                    .font(.body)

                if let delay = action.delay, delay > 0 {
                    Text("Wait \(delay)s before executing")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
    }

    var iconForAction: String {
        switch action.type {
        case .turnOn: return "power.circle.fill"
        case .turnOff: return "power.circle"
        case .setTemperature: return "thermometer"
        case .executeScene: return "sparkles"
        case .wait: return "clock"
        case .sendNotification: return "bell.fill"
        }
    }
}

// MARK: - Automation Builder

/// Automation builder manager
class AutomationBuilder: ObservableObject {
    static let shared = AutomationBuilder()

    @Published var customAutomations: [CustomAutomation] = []

    private let automationsKey = "com.homekittv.customAutomations"

    private init() {
        loadAutomations()
    }

    func createNewAutomation() {
        let automation = CustomAutomation(
            name: "New Automation",
            enabled: true,
            conditions: [],
            thenActions: [],
            elseActions: []
        )
        customAutomations.append(automation)
        saveAutomations()
    }

    func deleteAutomation(_ automation: CustomAutomation) {
        customAutomations.removeAll { $0.id == automation.id }
        saveAutomations()
    }

    private func loadAutomations() {
        if let data = UserDefaults.standard.data(forKey: automationsKey),
           let automations = try? JSONDecoder().decode([CustomAutomation].self, from: data) {
            customAutomations = automations
        }
    }

    private func saveAutomations() {
        if let data = try? JSONEncoder().encode(customAutomations) {
            UserDefaults.standard.set(data, forKey: automationsKey)
        }
    }
}

// MARK: - Models

/// Custom automation model
struct CustomAutomation: Identifiable, Codable {
    let id: UUID
    var name: String
    var enabled: Bool
    var conditions: [AutomationCondition]
    var thenActions: [AutomationAction]
    var elseActions: [AutomationAction]

    init(name: String, enabled: Bool, conditions: [AutomationCondition], thenActions: [AutomationAction], elseActions: [AutomationAction]) {
        self.id = UUID()
        self.name = name
        self.enabled = enabled
        self.conditions = conditions
        self.thenActions = thenActions
        self.elseActions = elseActions
    }
}

/// Automation condition
struct AutomationCondition: Identifiable, Codable {
    let id: UUID
    let type: ConditionType
    let description: String
    let value: String

    init(type: ConditionType, description: String, value: String) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.value = value
    }

    enum ConditionType: String, Codable {
        case time = "Time"
        case temperature = "Temperature"
        case humidity = "Humidity"
        case motion = "Motion"
        case doorOpen = "Door Open"
        case accessoryState = "Accessory State"
    }
}

/// Automation action
struct AutomationAction: Identifiable, Codable {
    let id: UUID
    let type: ActionType
    let description: String
    let target: String
    let value: String?
    let delay: Int?

    init(type: ActionType, description: String, target: String, value: String? = nil, delay: Int? = nil) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.target = target
        self.value = value
        self.delay = delay
    }

    enum ActionType: String, Codable {
        case turnOn = "Turn On"
        case turnOff = "Turn Off"
        case setTemperature = "Set Temperature"
        case executeScene = "Execute Scene"
        case wait = "Wait"
        case sendNotification = "Send Notification"
    }
}

#Preview {
    AutomationBuilderView()
        .environmentObject(HomeKitManager())
}
