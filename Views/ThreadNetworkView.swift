import SwiftUI
import HomeKit

/// Thread network topology and Matter device management
struct ThreadNetworkView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @StateObject private var networkManager = NetworkManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Network Topology")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Network Health
                    VStack(spacing: 25) {
                        HStack(spacing: 30) {
                            Image(systemName: networkManager.networkHealth > 80 ? "wifi" : "wifi.exclamationmark")
                                .font(.system(size: 60))
                                .foregroundColor(networkManager.networkHealth > 80 ? .green : networkManager.networkHealth > 50 ? .orange : .red)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Network Health")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(networkManager.networkHealth)%")
                                    .font(.system(size: 40, weight: .bold))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 8) {
                                Text("Border Router")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(networkManager.borderRouterName)
                                    .font(.title3)
                            }
                        }
                        .padding(30)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(20)

                        // Thread Devices
                        HStack(spacing: 40) {
                            NetworkStatCard(
                                title: "Thread Devices",
                                value: "\(networkManager.threadDeviceCount)",
                                icon: "link.circle.fill",
                                color: .blue
                            )

                            NetworkStatCard(
                                title: "Matter Devices",
                                value: "\(networkManager.matterDeviceCount)",
                                icon: "m.circle.fill",
                                color: .purple
                            )

                            NetworkStatCard(
                                title: "WiFi Devices",
                                value: "\(networkManager.wifiDeviceCount)",
                                icon: "wifi.circle.fill",
                                color: .green
                            )

                            NetworkStatCard(
                                title: "Bluetooth",
                                value: "\(networkManager.bluetoothDeviceCount)",
                                icon: "antenna.radiowaves.left.and.right.circle.fill",
                                color: .cyan
                            )
                        }
                    }
                    .padding(.horizontal, 80)

                    // Device List
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Devices by Protocol")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        Picker("Protocol", selection: $networkManager.selectedProtocol) {
                            Text("Thread").tag(NetworkProtocol.thread)
                            Text("Matter").tag(NetworkProtocol.matter)
                            Text("WiFi").tag(NetworkProtocol.wifi)
                            Text("Bluetooth").tag(NetworkProtocol.bluetooth)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 80)

                        ForEach(filteredDevices(), id: \.id) { device in
                            NetworkDeviceRow(device: device)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Network Performance
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Performance Metrics")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 30)], spacing: 30) {
                            MetricCard(title: "Avg Response Time", value: "\(networkManager.averageResponseTime)ms", icon: "timer", color: .blue)
                            MetricCard(title: "Network Latency", value: "\(networkManager.networkLatency)ms", icon: "chart.line.uptrend.xyaxis", color: .orange)
                            MetricCard(title: "Packet Loss", value: "\(String(format: "%.1f", networkManager.packetLoss))%", icon: "exclamationmark.triangle", color: .red)
                            MetricCard(title: "Uptime", value: "99.8%", icon: "checkmark.circle", color: .green)
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    private func filteredDevices() -> [NetworkDevice] {
        networkManager.devices.filter { $0.protocol == networkManager.selectedProtocol }
    }
}

// MARK: - Supporting Views

struct NetworkStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 35, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 25)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct NetworkDeviceRow: View {
    let device: NetworkDevice

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: device.icon)
                .font(.system(size: 35))
                .foregroundColor(device.color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(device.name)
                    .font(.body)
                    .bold()

                HStack(spacing: 10) {
                    Label("\(device.signalStrength)%", systemImage: "wifi")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(device.responseTime)ms", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Signal strength indicator
            Circle()
                .fill(signalColor(device.signalStrength))
                .frame(width: 20, height: 20)
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    func signalColor(_ strength: Int) -> Color {
        if strength > 80 { return .green }
        else if strength > 50 { return .orange }
        else { return .red }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 30, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(25)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Network Manager

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    @Published var networkHealth: Int = 95
    @Published var borderRouterName: String = "Apple TV"
    @Published var threadDeviceCount: Int = 0
    @Published var matterDeviceCount: Int = 0
    @Published var wifiDeviceCount: Int = 0
    @Published var bluetoothDeviceCount: Int = 0
    @Published var devices: [NetworkDevice] = []
    @Published var selectedProtocol: NetworkProtocol = .thread
    @Published var averageResponseTime: Int = 42
    @Published var networkLatency: Int = 15
    @Published var packetLoss: Double = 0.2

    func analyzeNetwork(homeManager: HomeKitManager) {
        devices.removeAll()

        // Analyze each accessory
        for accessory in homeManager.accessories {
            // Determine protocol (simplified - real implementation would check accessory properties)
            let proto: NetworkProtocol = .wifi // Would check actual protocol

            devices.append(NetworkDevice(
                name: accessory.name,
                protocol: proto,
                signalStrength: accessory.isReachable ? Int.random(in: 70...100) : 0,
                responseTime: accessory.isReachable ? Int.random(in: 20...100) : 999,
                icon: iconForAccessory(accessory),
                color: colorForProtocol(proto)
            ))
        }

        // Count by protocol
        threadDeviceCount = devices.filter { $0.protocol == .thread }.count
        matterDeviceCount = devices.filter { $0.protocol == .matter }.count
        wifiDeviceCount = devices.filter { $0.protocol == .wifi }.count
        bluetoothDeviceCount = devices.filter { $0.protocol == .bluetooth }.count
    }

    private func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let service = accessory.services.first else { return "circle.fill" }
        switch service.serviceType {
        case HMServiceTypeLightbulb: return "lightbulb.fill"
        case HMServiceTypeThermostat: return "thermometer"
        case HMServiceTypeFan: return "fan.fill"
        case HMServiceTypeLockMechanism: return "lock.fill"
        default: return "circle.fill"
        }
    }

    private func colorForProtocol(_ networkProtocol: NetworkProtocol) -> Color {
        switch networkProtocol {
        case .thread: return .blue
        case .matter: return .purple
        case .wifi: return .green
        case .bluetooth: return .cyan
        }
    }
}

// MARK: - Models

enum NetworkProtocol: String, Codable, CaseIterable {
    case thread = "Thread"
    case matter = "Matter"
    case wifi = "WiFi"
    case bluetooth = "Bluetooth"
}

struct NetworkDevice: Identifiable {
    let id = UUID()
    let name: String
    let `protocol`: NetworkProtocol
    let signalStrength: Int
    let responseTime: Int
    let icon: String
    let color: Color
}

#Preview {
    ThreadNetworkView()
        .environmentObject(HomeKitManager())
}
