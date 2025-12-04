import SwiftUI
import HomeKit

/// Customizable widget dashboard
///
/// Features:
/// - Drag-and-drop widget placement (simulated for tvOS)
/// - Multiple widget types
/// - Customizable layout
/// - Real-time data updates
struct WidgetDashboard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var widgetManager = WidgetManager.shared
    @State private var showingWidgetPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HStack {
                Text("Dashboard")
                    .font(.title)
                    .bold()

                Spacer()

                Button(action: {
                    showingWidgetPicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Widget")
                    }
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 80)

            if widgetManager.widgets.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No widgets yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Tap 'Add Widget' to customize your dashboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 25)], spacing: 25) {
                    ForEach(widgetManager.widgets) { widget in
                        WidgetView(widget: widget)
                    }
                }
                .padding(.horizontal, 80)
            }
        }
        .sheet(isPresented: $showingWidgetPicker) {
            WidgetPickerView(isPresented: $showingWidgetPicker)
                .environmentObject(homeManager)
        }
    }
}

/// Individual widget view
struct WidgetView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var integrationManager = IntegrationManager.shared
    let widget: DashboardWidget

    var body: some View {
        Group {
            switch widget.type {
            case .temperature:
                TemperatureWidget()
            case .energyUsage:
                EnergyUsageWidget()
            case .securityStatus:
                SecurityStatusWidget()
            case .cameraSnapshot:
                CameraSnapshotWidget()
            case .mostUsed:
                MostUsedWidget()
            case .upcomingAutomations:
                UpcomingAutomationsWidget()
            case .weather:
                WeatherWidget()
            case .quickAccessory:
                QuickAccessoryWidget(accessoryID: widget.config?["accessoryID"] ?? "")
            }
        }
    }
}

// MARK: - Widget Types

/// Temperature widget
struct TemperatureWidget: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var averageTemp: Double? {
        let temps = homeManager.accessories.compactMap { accessory -> Double? in
            homeManager.getSensorReadings(accessory)["Temperature"] as? Double
        }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "thermometer")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            if let temp = averageTemp {
                Text("\(Int(temp))°")
                    .font(.system(size: 45, weight: .bold))
            } else {
                Text("--°")
                    .font(.system(size: 45, weight: .bold))
                    .foregroundColor(.secondary)
            }

            Text("Average Temperature")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
}

/// Energy usage widget
struct EnergyUsageWidget: View {
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text("1.2 kW")
                .font(.system(size: 40, weight: .bold))

            Text("Current Usage")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("$0.18/hour")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(15)
    }
}

/// Security status widget
struct SecurityStatusWidget: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var unlockedLocks: Int {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLockMechanism } &&
            homeManager.getLockState(accessory.services.first { $0.serviceType == HMServiceTypeLockMechanism }!) == false
        }.count
    }

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: unlockedLocks == 0 ? "lock.fill" : "lock.open.fill")
                .font(.system(size: 40))
                .foregroundColor(unlockedLocks == 0 ? .green : .red)

            Text(unlockedLocks == 0 ? "Secure" : "\(unlockedLocks) Unlocked")
                .font(.system(size: 30, weight: .bold))

            Text("Security Status")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background((unlockedLocks == 0 ? Color.green : Color.red).opacity(0.1))
        .cornerRadius(15)
    }
}

/// Camera snapshot widget
struct CameraSnapshotWidget: View {
    var body: some View {
        VStack(spacing: 10) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "video.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.secondary)
                )
                .cornerRadius(10)

            Text("Front Door")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Most used accessories widget
struct MostUsedWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.orange)
                Text("Most Used")
                    .font(.body)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Living Room Lights")
                    .font(.caption)
                Text("Kitchen Outlet")
                    .font(.caption)
                Text("Front Door Lock")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
}

/// Upcoming automations widget
struct UpcomingAutomationsWidget: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Up Next")
                    .font(.body)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("7:00 PM")
                        .font(.caption)
                        .bold()
                    Text("Evening Routine")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("10:00 PM")
                        .font(.caption)
                        .bold()
                    Text("Good Night")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
}

/// Weather widget
struct WeatherWidget: View {
    @ObservedObject private var integrationManager = IntegrationManager.shared

    var body: some View {
        VStack(spacing: 12) {
            if let weather = integrationManager.weather {
                Image(systemName: weather.icon)
                    .font(.system(size: 35))
                    .foregroundColor(.orange)

                Text("\(weather.temperature)°")
                    .font(.system(size: 35, weight: .bold))

                Text(weather.condition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.secondary)

                Text("--°")
                    .font(.system(size: 35, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
}

/// Quick accessory widget
struct QuickAccessoryWidget: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessoryID: String

    var accessory: HMAccessory? {
        homeManager.accessories.first { $0.uniqueIdentifier.uuidString == accessoryID }
    }

    var body: some View {
        if let accessory = accessory {
            VStack(spacing: 12) {
                Image(systemName: iconForAccessory(accessory))
                    .font(.system(size: 35))
                    .foregroundColor(.blue)

                Text(accessory.name)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Button(action: {
                    homeManager.toggleAccessory(accessory)
                }) {
                    Image(systemName: homeManager.getPowerState(accessory) ? "power.circle.fill" : "power.circle")
                        .font(.system(size: 30))
                        .foregroundColor(homeManager.getPowerState(accessory) ? .green : .secondary)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(15)
        }
    }

    func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let service = accessory.services.first else { return "circle.fill" }
        switch service.serviceType {
        case HMServiceTypeLightbulb: return "lightbulb.fill"
        case HMServiceTypeFan: return "fan.fill"
        default: return "circle.fill"
        }
    }
}

/// Widget picker view
struct WidgetPickerView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var widgetManager = WidgetManager.shared
    @Binding var isPresented: Bool

    let widgetTypes: [(WidgetType, String, String, Color)] = [
        (.temperature, "Temperature", "Average home temperature", .orange),
        (.energyUsage, "Energy Usage", "Current power consumption", .yellow),
        (.securityStatus, "Security", "Lock status overview", .green),
        (.weather, "Weather", "Current weather conditions", .blue),
        (.mostUsed, "Most Used", "Frequently controlled devices", .purple),
        (.upcomingAutomations, "Up Next", "Upcoming automations", .cyan)
    ]

    var body: some View {
        VStack(spacing: 30) {
            Text("Add Widget")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 25)], spacing: 25) {
                ForEach(widgetTypes, id: \.0) { type, title, description, color in
                    Button(action: {
                        widgetManager.addWidget(type: type)
                        isPresented = false
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: iconForType(type))
                                .font(.system(size: 40))
                                .foregroundColor(color)

                            Text(title)
                                .font(.title3)
                                .bold()
                                .foregroundColor(.primary)

                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(color.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 80)

            Button("Cancel") {
                isPresented = false
            }
            .font(.title2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 80)
            .background(Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
    }

    func iconForType(_ type: WidgetType) -> String {
        switch type {
        case .temperature: return "thermometer"
        case .energyUsage: return "bolt.fill"
        case .securityStatus: return "lock.fill"
        case .cameraSnapshot: return "video.fill"
        case .mostUsed: return "star.fill"
        case .upcomingAutomations: return "clock.fill"
        case .weather: return "cloud.sun.fill"
        case .quickAccessory: return "power"
        }
    }
}

// MARK: - Widget Manager

/// Widget dashboard manager
class WidgetManager: ObservableObject {
    static let shared = WidgetManager()

    @Published var widgets: [DashboardWidget] = []

    private let widgetsKey = "com.homekittv.dashboardWidgets"

    private init() {
        loadWidgets()
    }

    func addWidget(type: WidgetType, config: [String: String]? = nil) {
        let widget = DashboardWidget(type: type, position: widgets.count, config: config)
        widgets.append(widget)
        saveWidgets()
    }

    func removeWidget(_ widget: DashboardWidget) {
        widgets.removeAll { $0.id == widget.id }
        saveWidgets()
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        widgets.move(fromOffsets: source, toOffset: destination)
        // Update positions
        for (index, _) in widgets.enumerated() {
            widgets[index].position = index
        }
        saveWidgets()
    }

    private func loadWidgets() {
        if let data = UserDefaults.standard.data(forKey: widgetsKey),
           let widgets = try? JSONDecoder().decode([DashboardWidget].self, from: data) {
            self.widgets = widgets
        } else {
            // Default widgets
            widgets = [
                DashboardWidget(type: .temperature, position: 0),
                DashboardWidget(type: .weather, position: 1),
                DashboardWidget(type: .securityStatus, position: 2),
                DashboardWidget(type: .upcomingAutomations, position: 3)
            ]
        }
    }

    private func saveWidgets() {
        if let data = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(data, forKey: widgetsKey)
        }
    }
}

// MARK: - Models

/// Dashboard widget model
struct DashboardWidget: Identifiable, Codable {
    let id: UUID
    let type: WidgetType
    var position: Int
    var config: [String: String]?

    init(type: WidgetType, position: Int, config: [String: String]? = nil) {
        self.id = UUID()
        self.type = type
        self.position = position
        self.config = config
    }
}

/// Widget types
enum WidgetType: String, Codable {
    case temperature = "Temperature"
    case energyUsage = "Energy Usage"
    case securityStatus = "Security Status"
    case cameraSnapshot = "Camera Snapshot"
    case mostUsed = "Most Used"
    case upcomingAutomations = "Upcoming Automations"
    case weather = "Weather"
    case quickAccessory = "Quick Accessory"
}

#Preview {
    WidgetDashboard()
        .environmentObject(HomeKitManager())
}
