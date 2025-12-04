import SwiftUI
import HomeKit

/// Accessory Diagnostics & Health View
///
/// Comprehensive diagnostics interface for HomeKit accessories:
/// - Last seen/communication status
/// - Firmware version info
/// - Signal strength indicators
/// - Battery health trends
/// - Troubleshooting tips
/// - Connectivity history
///
/// **Integration**: Uses HomeKitManager for accessory data
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Uses @EnvironmentObject to prevent retain cycles
///
/// **Features**:
/// - Health scores
/// - Connectivity monitoring
/// - Battery analytics
/// - Firmware tracking
/// - Troubleshooting wizard
///
/// - SeeAlso: `HomeKitManager`, `HMAccessory`
struct AccessoryDiagnosticsView: View {
    @EnvironmentObject var homeManager: HomeKitManager

    @State private var selectedAccessory: HMAccessory?
    @State private var sortBy: SortOption = .name
    @State private var filterBy: FilterOption = .all

    enum SortOption: String, CaseIterable {
        case name = "Name"
        case health = "Health"
        case battery = "Battery"
        case reachability = "Status"
    }

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case offline = "Offline"
        case lowBattery = "Low Battery"
        case issues = "Issues"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                headerSection

                // Filter & Sort Controls
                controlsSection

                // Statistics
                statisticsSection

                // Accessories List
                accessoriesListSection

                // Selected Accessory Details
                if let accessory = selectedAccessory {
                    accessoryDetailsSection(accessory)
                }
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Accessory Diagnostics")
                    .font(.largeTitle)
                    .bold()
                Text("Monitor health and troubleshoot connectivity issues")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "stethoscope")
                .font(.system(size: 60))
                .foregroundColor(.blue)
        }
    }

    // MARK: - Controls Section

    private var controlsSection: some View {
        HStack(spacing: 30) {
            // Sort Picker
            HStack {
                Text("Sort by:")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                Picker("Sort", selection: $sortBy) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
            }

            // Filter Picker
            HStack {
                Text("Filter:")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                Picker("Filter", selection: $filterBy) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 400)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        let offlineCount = homeManager.accessories.filter { !$0.isReachable }.count
        let _ = homeManager.accessories.filter { hasLowBattery($0) }.count
        let healthScore = calculateOverallHealth()

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 30) {
            StatCard(
                title: "Total Devices",
                value: "\(homeManager.accessories.count)",
                icon: "apps.iphone",
                color: .blue
            )

            StatCard(
                title: "Online",
                value: "\(homeManager.accessories.count - offlineCount)",
                icon: "wifi",
                color: .green
            )

            StatCard(
                title: "Offline",
                value: "\(offlineCount)",
                icon: "wifi.slash",
                color: offlineCount > 0 ? .red : .gray
            )

            StatCard(
                title: "Health Score",
                value: "\(healthScore)%",
                icon: "heart.fill",
                color: colorForHealth(healthScore)
            )
        }
    }

    // MARK: - Accessories List Section

    private var accessoriesListSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Accessories (\(filteredAndSortedAccessories.count))")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            if filteredAndSortedAccessories.isEmpty {
                Text("No accessories match the current filter")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(40)
            } else {
                VStack(spacing: 15) {
                    ForEach(filteredAndSortedAccessories, id: \.uniqueIdentifier) { accessory in
                        DiagnosticAccessoryRow(
                            accessory: accessory,
                            isSelected: selectedAccessory?.uniqueIdentifier == accessory.uniqueIdentifier
                        ) {
                            selectedAccessory = accessory
                        }
                    }
                }
            }
        }
    }

    // MARK: - Accessory Details Section

    private func accessoryDetailsSection(_ accessory: HMAccessory) -> some View {
        VStack(alignment: .leading, spacing: 25) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(accessory.name)
                        .font(.title)
                        .bold()

                    if let room = accessory.room {
                        Text(room.name)
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Close") {
                    selectedAccessory = nil
                }
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
            }

            Divider()

            // Device Information
            VStack(alignment: .leading, spacing: 15) {
                Text("Device Information")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                DiagnosticInfoRow(label: "Manufacturer", value: accessory.manufacturer ?? "Unknown")
                DiagnosticInfoRow(label: "Model", value: accessory.model ?? "Unknown")
                DiagnosticInfoRow(label: "Category", value: accessory.category.localizedDescription)
                DiagnosticInfoRow(label: "Unique ID", value: accessory.uniqueIdentifier.uuidString)
            }

            Divider()

            // Connectivity Status
            VStack(alignment: .leading, spacing: 15) {
                Text("Connectivity")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                HStack {
                    Label(accessory.isReachable ? "Online" : "Offline", systemImage: accessory.isReachable ? "wifi" : "wifi.slash")
                        .foregroundColor(accessory.isReachable ? .green : .red)

                    Spacer()

                    if accessory.isReachable {
                        Text("Responding")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                    } else {
                        Text("Not Responding")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                    }
                }

                if accessory.isBlocked {
                    Label("Device is blocked", systemImage: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Battery Status (if applicable)
            if let batteryLevel = getBatteryLevel(accessory) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Battery")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()

                    HStack {
                        Image(systemName: batteryIcon(batteryLevel))
                            .font(.title)
                            .foregroundColor(batteryColor(batteryLevel))

                        VStack(alignment: .leading) {
                            Text("\(batteryLevel)%")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .bold()

                            Text(batteryStatus(batteryLevel))
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Battery health indicator
                        VStack {
                            Text("Health")
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                            Text(batteryHealth(batteryLevel))
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .bold()
                                .foregroundColor(batteryColor(batteryLevel))
                        }
                    }

                    // Low battery warning
                    if batteryLevel < 20 {
                        Label("Low battery - replace soon", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .padding(12)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                Divider()
            }

            // Services
            VStack(alignment: .leading, spacing: 15) {
                Text("Services (\(accessory.services.count))")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                ForEach(accessory.services, id: \.uniqueIdentifier) { service in
                    ServiceRow(service: service)
                }
            }

            Divider()

            // Troubleshooting
            VStack(alignment: .leading, spacing: 15) {
                Text("Troubleshooting")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                if !accessory.isReachable {
                    TroubleshootingTip(
                        icon: "wifi.slash",
                        title: "Device Not Responding",
                        tips: [
                            "Check if the device has power",
                            "Verify Wi-Fi network is working",
                            "Move device closer to router/hub",
                            "Restart the HomeKit hub (Apple TV/HomePod)",
                            "Remove and re-add the accessory"
                        ]
                    )
                } else if let battery = getBatteryLevel(accessory), battery < 20 {
                    TroubleshootingTip(
                        icon: "battery.25",
                        title: "Low Battery",
                        tips: [
                            "Replace batteries soon",
                            "Keep spare batteries available",
                            "Device may become unresponsive when battery dies"
                        ]
                    )
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("No issues detected")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.green)
                    }
                    .padding(15)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(30)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }

    // MARK: - Helper Methods

    private var filteredAndSortedAccessories: [HMAccessory] {
        var accessories = homeManager.accessories

        // Apply filter
        switch filterBy {
        case .all:
            break
        case .offline:
            accessories = accessories.filter { !$0.isReachable }
        case .lowBattery:
            accessories = accessories.filter { hasLowBattery($0) }
        case .issues:
            accessories = accessories.filter { !$0.isReachable || hasLowBattery($0) }
        }

        // Apply sort
        switch sortBy {
        case .name:
            accessories = accessories.sorted { $0.name < $1.name }
        case .health:
            accessories = accessories.sorted { calculateAccessoryHealth($0) > calculateAccessoryHealth($1) }
        case .battery:
            accessories = accessories.sorted { (getBatteryLevel($0) ?? 100) < (getBatteryLevel($1) ?? 100) }
        case .reachability:
            accessories = accessories.sorted { $0.isReachable && !$1.isReachable }
        }

        return accessories
    }

    private func getBatteryLevel(_ accessory: HMAccessory) -> Int? {
        for service in accessory.services {
            if let batteryChar = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeBatteryLevel
            }) {
                return batteryChar.value as? Int
            }
        }
        return nil
    }

    private func hasLowBattery(_ accessory: HMAccessory) -> Bool {
        if let battery = getBatteryLevel(accessory) {
            return battery < 20
        }
        return false
    }

    private func calculateAccessoryHealth(_ accessory: HMAccessory) -> Int {
        var health = 100

        // Reachability
        if !accessory.isReachable {
            health -= 50
        }

        // Battery
        if let battery = getBatteryLevel(accessory) {
            if battery < 10 {
                health -= 30
            } else if battery < 20 {
                health -= 15
            }
        }

        // Blocked
        if accessory.isBlocked {
            health -= 25
        }

        return max(0, health)
    }

    private func calculateOverallHealth() -> Int {
        guard !homeManager.accessories.isEmpty else { return 100 }

        let totalHealth = homeManager.accessories.reduce(0) { $0 + calculateAccessoryHealth($1) }
        return totalHealth / homeManager.accessories.count
    }

    private func colorForHealth(_ health: Int) -> Color {
        if health >= 80 {
            return .green
        } else if health >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    private func batteryIcon(_ level: Int) -> String {
        if level >= 75 {
            return "battery.100"
        } else if level >= 50 {
            return "battery.75"
        } else if level >= 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    private func batteryColor(_ level: Int) -> Color {
        if level >= 50 {
            return .green
        } else if level >= 20 {
            return .orange
        } else {
            return .red
        }
    }

    private func batteryStatus(_ level: Int) -> String {
        if level >= 80 {
            return "Excellent"
        } else if level >= 50 {
            return "Good"
        } else if level >= 20 {
            return "Fair"
        } else {
            return "Low"
        }
    }

    private func batteryHealth(_ level: Int) -> String {
        if level >= 80 {
            return "Excellent"
        } else if level >= 50 {
            return "Good"
        } else if level >= 20 {
            return "Degraded"
        } else {
            return "Critical"
        }
    }
}

// MARK: - Diagnostic Accessory Row

struct DiagnosticAccessoryRow: View {
    let accessory: HMAccessory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Health Indicator
                Circle()
                    .fill(healthColor)
                    .frame(width: 15, height: 15)

                // Icon
                Image(systemName: iconForAccessory)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(accessory.isReachable ? .blue : .gray)
                    .frame(width: 40)

                // Name
                VStack(alignment: .leading, spacing: 5) {
                    Text(accessory.name)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()

                    if let room = accessory.room {
                        Text(room.name)
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Status Badges
                HStack(spacing: 10) {
                    if !accessory.isReachable {
                        StatusBadge(text: "Offline", color: .red)
                    } else {
                        StatusBadge(text: "Online", color: .green)
                    }

                    if let battery = getBatteryLevel(accessory) {
                        StatusBadge(text: "\(battery)%", color: batteryColor(battery))
                    }

                    StatusBadge(text: "\(healthScore)%", color: healthColor)
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var iconForAccessory: String {
        if let service = accessory.services.first {
            switch service.serviceType {
            case HMServiceTypeLightbulb: return "lightbulb.fill"
            case HMServiceTypeOutlet: return "powerplug.fill"
            case HMServiceTypeSwitch: return "switch.2"
            case HMServiceTypeThermostat: return "thermometer"
            case HMServiceTypeFan: return "fan.fill"
            case HMServiceTypeLockMechanism: return "lock.fill"
            default: return "app.connected.to.app.below.fill"
            }
        }
        return "app.connected.to.app.below.fill"
    }

    private func getBatteryLevel(_ accessory: HMAccessory) -> Int? {
        for service in accessory.services {
            if let batteryChar = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeBatteryLevel
            }) {
                return batteryChar.value as? Int
            }
        }
        return nil
    }

    private func batteryColor(_ level: Int) -> Color {
        if level >= 50 {
            return .green
        } else if level >= 20 {
            return .orange
        } else {
            return .red
        }
    }

    private var healthScore: Int {
        var health = 100

        if !accessory.isReachable {
            health -= 50
        }

        if let battery = getBatteryLevel(accessory), battery < 20 {
            health -= 30
        }

        return max(0, health)
    }

    private var healthColor: Color {
        if healthScore >= 80 {
            return .green
        } else if healthScore >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Views

struct DiagnosticInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()
        }
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct ServiceRow: View {
    let service: HMService

    var body: some View {
        HStack {
            Image(systemName: iconForService)
                .foregroundColor(.blue)

            Text(serviceTypeName)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

            Spacer()

            Text("\(service.characteristics.count) characteristics")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var iconForService: String {
        switch service.serviceType {
        case HMServiceTypeLightbulb: return "lightbulb.fill"
        case HMServiceTypeOutlet: return "powerplug.fill"
        case HMServiceTypeThermostat: return "thermometer"
        case HMServiceTypeFan: return "fan.fill"
        default: return "gear"
        }
    }

    private var serviceTypeName: String {
        switch service.serviceType {
        case HMServiceTypeLightbulb: return "Lightbulb"
        case HMServiceTypeOutlet: return "Outlet"
        case HMServiceTypeThermostat: return "Thermostat"
        case HMServiceTypeFan: return "Fan"
        default: return service.serviceType
        }
    }
}

struct TroubleshootingTip: View {
    let icon: String
    let title: String
    let tips: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.orange)
                Text(title)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                        Text(tip)
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    AccessoryDiagnosticsView()
        .environmentObject(HomeKitManager())
}
