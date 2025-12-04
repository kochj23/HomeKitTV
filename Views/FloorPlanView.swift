import SwiftUI
import HomeKit

/// Floor plan view with accessory placement
///
/// Features:
/// - Import floor plan image
/// - Place accessories on floor plan
/// - Visual status indicators
/// - Heat map of activity
/// - Signal strength visualization
struct FloorPlanView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var floorPlanManager = FloorPlanManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Floor Plan")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Button(action: {
                            floorPlanManager.showingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("Import Plan")
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

                    if floorPlanManager.floorPlanImage == nil {
                        VStack(spacing: 30) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Floor Plan")
                                .font(.title2)
                            Text("Import a floor plan image to visualize your accessories")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        // Floor Plan Display
                        VStack(spacing: 30) {
                            // View mode selector
                            Picker("View Mode", selection: $floorPlanManager.viewMode) {
                                Text("Placement").tag(FloorPlanViewMode.placement)
                                Text("Status").tag(FloorPlanViewMode.status)
                                Text("Activity Heatmap").tag(FloorPlanViewMode.heatmap)
                                Text("Signal Strength").tag(FloorPlanViewMode.signalStrength)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 80)

                            // Floor plan canvas
                            FloorPlanCanvas(
                                accessories: homeManager.accessories,
                                viewMode: floorPlanManager.viewMode
                            )
                            .frame(height: 800)
                            .padding(.horizontal, 80)

                            // Legend
                            FloorPlanLegend(viewMode: floorPlanManager.viewMode)
                                .padding(.horizontal, 80)
                        }
                    }

                    // Accessory List with Placement
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Accessory Placement")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        ForEach(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
                            AccessoryPlacementRow(accessory: accessory)
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// Floor plan canvas with accessory markers
struct FloorPlanCanvas: View {
    let accessories: [HMAccessory]
    let viewMode: FloorPlanViewMode
    @ObservedObject private var floorPlanManager = FloorPlanManager.shared

    var body: some View {
        ZStack {
            // Floor plan image
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                    Image(systemName: "map.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.secondary)
                )

            // Accessory markers
            ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                if let position = floorPlanManager.getPosition(for: accessory) {
                    AccessoryMarker(accessory: accessory, viewMode: viewMode)
                        .position(x: position.x, y: position.y)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}

/// Accessory marker on floor plan
struct AccessoryMarker: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessory: HMAccessory
    let viewMode: FloorPlanViewMode

    var isOn: Bool {
        homeManager.getPowerState(accessory)
    }

    var signalStrength: Int {
        // Placeholder - would need RSSI data
        accessory.isReachable ? Int.random(in: 60...100) : 0
    }

    var markerColor: Color {
        switch viewMode {
        case .status:
            return isOn ? .green : .gray
        case .signalStrength:
            if signalStrength > 80 { return .green }
            else if signalStrength > 50 { return .orange }
            else { return .red }
        case .heatmap:
            // Based on activity - placeholder
            return .orange
        default:
            return .blue
        }
    }

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: 40, height: 40)

                Image(systemName: iconForAccessory(accessory))
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            Text(accessory.name)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }

    func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let service = accessory.services.first else { return "circle.fill" }
        switch service.serviceType {
        case HMServiceTypeLightbulb: return "lightbulb.fill"
        case HMServiceTypeThermostat: return "thermometer"
        case HMServiceTypeFan: return "fan.fill"
        case HMServiceTypeLockMechanism: return "lock.fill"
        default: return "circle.fill"
        }
    }
}

/// Floor plan legend
struct FloorPlanLegend: View {
    let viewMode: FloorPlanViewMode

    var body: some View {
        HStack(spacing: 40) {
            Text("Legend:")
                .font(.title3)
                .bold()

            switch viewMode {
            case .status:
                LegendItem(color: .green, text: "On")
                LegendItem(color: .gray, text: "Off")

            case .signalStrength:
                LegendItem(color: .green, text: "Strong (>80%)")
                LegendItem(color: .orange, text: "Medium (50-80%)")
                LegendItem(color: .red, text: "Weak (<50%)")

            case .heatmap:
                LegendItem(color: .red, text: "High Activity")
                LegendItem(color: .orange, text: "Medium Activity")
                LegendItem(color: .blue, text: "Low Activity")

            default:
                LegendItem(color: .blue, text: "Accessory")
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 15, height: 15)
            Text(text)
                .font(.body)
        }
    }
}

/// Accessory placement row
struct AccessoryPlacementRow: View {
    let accessory: HMAccessory
    @ObservedObject private var floorPlanManager = FloorPlanManager.shared

    var position: CGPoint? {
        floorPlanManager.getPosition(for: accessory)
    }

    var body: some View {
        HStack {
            Image(systemName: iconForAccessory(accessory))
                .font(.system(size: 25))
                .frame(width: 40)

            Text(accessory.name)
                .font(.body)

            Spacer()

            if let pos = position {
                Text("X: \(Int(pos.x)), Y: \(Int(pos.y))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
            } else {
                Text("Not placed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                // Place accessory
                floorPlanManager.setPosition(for: accessory, position: CGPoint(x: 400, y: 400))
            }) {
                Image(systemName: position == nil ? "mappin.circle" : "pencil.circle")
                    .font(.system(size: 25))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }

    func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let service = accessory.services.first else { return "circle.fill" }
        switch service.serviceType {
        case HMServiceTypeLightbulb: return "lightbulb.fill"
        case HMServiceTypeThermostat: return "thermometer"
        default: return "circle.fill"
        }
    }
}

// MARK: - Floor Plan Manager

/// Floor plan manager for accessory placement
class FloorPlanManager: ObservableObject {
    static let shared = FloorPlanManager()

    @Published var floorPlanImage: String?
    @Published var accessoryPositions: [String: CGPoint] = [:]
    @Published var viewMode: FloorPlanViewMode = .placement
    @Published var showingImagePicker = false

    private let positionsKey = "com.homekittv.floorPlanPositions"

    private init() {
        loadPositions()
    }

    func getPosition(for accessory: HMAccessory) -> CGPoint? {
        accessoryPositions[accessory.uniqueIdentifier.uuidString]
    }

    func setPosition(for accessory: HMAccessory, position: CGPoint) {
        accessoryPositions[accessory.uniqueIdentifier.uuidString] = position
        savePositions()
    }

    private func loadPositions() {
        if let data = UserDefaults.standard.data(forKey: positionsKey),
           let positions = try? JSONDecoder().decode([String: CGPoint].self, from: data) {
            accessoryPositions = positions
        }
    }

    private func savePositions() {
        if let data = try? JSONEncoder().encode(accessoryPositions) {
            UserDefaults.standard.set(data, forKey: positionsKey)
        }
    }
}

/// Floor plan view modes
enum FloorPlanViewMode: String, Codable {
    case placement = "Placement"
    case status = "Status"
    case heatmap = "Activity Heatmap"
    case signalStrength = "Signal Strength"
}


#Preview {
    FloorPlanView()
        .environmentObject(HomeKitManager())
}
