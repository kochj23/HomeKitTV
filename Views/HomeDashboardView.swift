import SwiftUI
import HomeKit

/// Home Dashboard Status Overview
///
/// Enhanced dashboard showing at-a-glance home status:
/// - Open doors/windows indicator
/// - Lights currently on
/// - Temperature readings across rooms
/// - Security system status
/// - Live activity feed
/// - Quick status indicators
///
/// **Integration**: Can be embedded in HomeView or used standalone
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Uses @ObservedObject to prevent retain cycles
///
/// **Features**:
/// - Real-time status updates
/// - Security alerts
/// - Climate monitoring
/// - Activity timeline
/// - Quick glance widgets
///
/// - SeeAlso: `HomeKitManager`, `Settings`
struct HomeDashboardStatusView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var notificationManager = NotificationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Status Cards Row
            statusCardsSection

            // Security & Climate Overview
            HStack(spacing: 30) {
                securityStatusSection
                climateStatusSection
            }

            // Activity Feed
            activityFeedSection
        }
    }

    // MARK: - Status Cards

    private var statusCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            // Lights On
            StatusCard(
                title: "Lights On",
                value: "\(lightsOnCount)",
                icon: "lightbulb.fill",
                color: lightsOnCount > 0 ? .yellow : .gray,
                isAlert: false
            )

            // Doors/Windows Open
            StatusCard(
                title: "Open",
                value: "\(openDoorsWindowsCount)",
                icon: "door.left.hand.open",
                color: openDoorsWindowsCount > 0 ? .orange : .gray,
                isAlert: openDoorsWindowsCount > 0
            )

            // Locks Status
            StatusCard(
                title: "Locks",
                value: locksStatus,
                icon: "lock.fill",
                color: allLocksSecured ? .green : .red,
                isAlert: !allLocksSecured
            )

            // Notifications
            StatusCard(
                title: "Alerts",
                value: "\(notificationManager.unreadCount)",
                icon: "bell.fill",
                color: notificationManager.unreadCount > 0 ? .red : .gray,
                isAlert: notificationManager.unreadCount > 0
            )
        }
    }

    // MARK: - Security Status

    private var securityStatusSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "shield.fill")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(allLocksSecured ? .green : .red)

                Text("Security Status")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                Text(allLocksSecured ? "Secured" : "Unsecured")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()
                    .foregroundColor(allLocksSecured ? .green : .red)
            }

            Divider()

            // Lock Status
            VStack(alignment: .leading, spacing: 12) {
                ForEach(locks, id: \.uniqueIdentifier) { lock in
                    HStack {
                        Image(systemName: isLocked(lock) ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(isLocked(lock) ? .green : .red)

                        Text(lock.name)
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                        Spacer()

                        Text(isLocked(lock) ? "Locked" : "Unlocked")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(isLocked(lock) ? .green : .red)
                            .bold()
                    }
                }

                if locks.isEmpty {
                    Text("No locks configured")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }
            }

            // Open Doors/Windows
            if openDoorsWindowsCount > 0 {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("\(openDoorsWindowsCount) doors/windows open:")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()

                    ForEach(openDoorsWindows, id: \.uniqueIdentifier) { accessory in
                        HStack {
                            Image(systemName: "door.left.hand.open")
                                .foregroundColor(.orange)

                            Text(accessory.name)
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                            Spacer()

                            Text("Open")
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(allLocksSecured ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Climate Status

    private var climateStatusSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "thermometer")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.blue)

                Text("Climate")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                if let avgTemp = averageTemperature {
                    Text(String(format: "%.1f°", avgTemp))
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .foregroundColor(.blue)
                }
            }

            Divider()

            // Temperature Readings
            VStack(alignment: .leading, spacing: 12) {
                ForEach(temperatureSensors, id: \.uniqueIdentifier) { sensor in
                    if let temp = getTemperature(sensor) {
                        HStack {
                            Image(systemName: "thermometer")
                                .foregroundColor(colorForTemperature(temp))

                            Text(sensor.room?.name ?? sensor.name)
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                            Spacer()

                            Text(String(format: "%.1f°", temp))
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .bold()
                                .foregroundColor(colorForTemperature(temp))
                        }
                    }
                }

                if temperatureSensors.isEmpty {
                    Text("No temperature sensors")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }
            }

            // Thermostats
            if !thermostats.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Thermostats:")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()

                    ForEach(thermostats, id: \.uniqueIdentifier) { thermostat in
                        HStack {
                            Image(systemName: "snowflake")
                                .foregroundColor(.blue)

                            Text(thermostat.name)
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                            Spacer()

                            if let target = getTargetTemperature(thermostat) {
                                Text(String(format: "→ %.1f°", target))
                                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    .bold()
                            }
                        }
                    }
                }
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Activity Feed

    private var activityFeedSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                Text("\(settings.activityHistory.count) events")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            if settings.activityHistory.isEmpty {
                Text("No recent activity")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(30)
            } else {
                VStack(spacing: 10) {
                    ForEach(settings.activityHistory.prefix(5)) { activity in
                        ActivityFeedRow(activity: activity)
                    }
                }
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Helper Properties

    private var lightsOnCount: Int {
        homeManager.accessories.filter { accessory in
            guard accessory.isReachable else { return false }
            return accessory.services.contains { service in
                service.serviceType == HMServiceTypeLightbulb &&
                service.characteristics.contains { characteristic in
                    characteristic.characteristicType == HMCharacteristicTypePowerState &&
                    (characteristic.value as? Bool) == true
                }
            }
        }.count
    }

    private var openDoorsWindowsCount: Int {
        openDoorsWindows.count
    }

    private var openDoorsWindows: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            guard accessory.isReachable else { return false }
            return accessory.services.contains { service in
                service.characteristics.contains { characteristic in
                    characteristic.characteristicType == "0000006A-0000-1000-8000-0026BB765291" && // Contact Sensor State
                    (characteristic.value as? Int) == 0 // 0 = open
                }
            }
        }
    }

    private var locks: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLockMechanism }
        }
    }

    private var allLocksSecured: Bool {
        guard !locks.isEmpty else { return true }
        return locks.allSatisfy { isLocked($0) }
    }

    private var locksStatus: String {
        let lockedCount = locks.filter { isLocked($0) }.count
        let totalLocks = locks.count
        return totalLocks > 0 ? "\(lockedCount)/\(totalLocks)" : "N/A"
    }

    private var temperatureSensors: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { service in
                service.characteristics.contains {
                    $0.characteristicType == HMCharacteristicTypeCurrentTemperature
                }
            }
        }
    }

    private var thermostats: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeThermostat }
        }
    }

    private var averageTemperature: Double? {
        let temps = temperatureSensors.compactMap { getTemperature($0) }
        guard !temps.isEmpty else { return nil }
        return temps.reduce(0, +) / Double(temps.count)
    }

    // MARK: - Helper Methods

    private func isLocked(_ accessory: HMAccessory) -> Bool {
        for service in accessory.services where service.serviceType == HMServiceTypeLockMechanism {
            if let lockChar = service.characteristics.first(where: {
                $0.characteristicType == "0000001E-0000-1000-8000-0026BB765291" // Lock Target State
            }) {
                return (lockChar.value as? Int) == 1 // 1 = secured
            }
        }
        return false
    }

    private func getTemperature(_ accessory: HMAccessory) -> Double? {
        for service in accessory.services {
            if let tempChar = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeCurrentTemperature
            }) {
                if let celsius = tempChar.value as? Double {
                    // Convert to Fahrenheit
                    return (celsius * 9/5) + 32
                }
            }
        }
        return nil
    }

    private func getTargetTemperature(_ accessory: HMAccessory) -> Double? {
        for service in accessory.services where service.serviceType == HMServiceTypeThermostat {
            if let tempChar = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeTargetTemperature
            }) {
                if let celsius = tempChar.value as? Double {
                    return (celsius * 9/5) + 32
                }
            }
        }
        return nil
    }

    private func colorForTemperature(_ temp: Double) -> Color {
        if temp < 60 {
            return .blue
        } else if temp > 80 {
            return .red
        } else {
            return .green
        }
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isAlert: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 70, height: 70)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(color)

                if isAlert {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 15, height: 15)
                        .offset(x: 25, y: -25)
                }
            }

            Text(value)
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Activity Feed Row

struct ActivityFeedRow: View {
    let activity: ActivityEntry

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: iconForAction)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(colorForAction)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.accessoryName)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Text(activity.action)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(activity.timestamp, style: .relative)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var iconForAction: String {
        let action = activity.action.lowercased()
        if action.contains("lock") {
            return "lock.fill"
        } else if action.contains("temperature") || action.contains("thermostat") {
            return "thermometer"
        } else if action.contains("brightness") || action.contains("light") {
            return "lightbulb.fill"
        } else if action.contains("scene") {
            return "sparkles"
        } else if action.contains("fan") {
            return "fan.fill"
        } else {
            return "app.fill"
        }
    }

    private var colorForAction: Color {
        let action = activity.action.lowercased()
        if action.contains("lock") {
            return .green
        } else if action.contains("temperature") {
            return .blue
        } else if action.contains("brightness") || action.contains("light") {
            return .yellow
        } else if action.contains("scene") {
            return .purple
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        HomeDashboardStatusView()
            .environmentObject(HomeKitManager())
            .padding(80)
    }
}
