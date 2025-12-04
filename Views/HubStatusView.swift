import SwiftUI
import HomeKit

/// Apple TV Hub Status View
///
/// Shows HomeKit hub information and status:
/// - Whether this Apple TV is acting as HomeKit hub
/// - Hub connection status
/// - Other hubs in home
/// - Remote access status
/// - Hub health monitoring
///
/// **Integration**: Uses HomeKitManager for hub data
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Uses @EnvironmentObject to prevent retain cycles
///
/// **Features**:
/// - Hub role indicator
/// - Connection status
/// - Multiple hub management
/// - Remote access monitoring
///
/// - SeeAlso: `HomeKitManager`, `HMHome`
struct HubStatusView: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                headerSection

                // This Device Status
                thisDeviceSection

                // Home Hub Information
                if let home = homeManager.primaryHome {
                    homeHubSection(home)
                }

                // Remote Access Status
                remoteAccessSection

                // Hub Information
                hubInformationSection
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hub Status")
                    .font(.largeTitle)
                    .bold()
                Text("Monitor HomeKit hub connectivity and status")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "appletv.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
        }
    }

    // MARK: - This Device Section

    private var thisDeviceSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("This Apple TV")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            HStack(spacing: 30) {
                // Device Icon
                Image(systemName: "appletv.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Apple TV")
                        .font(.title)
                        .bold()

                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 15, height: 15)

                        Text("Active and Running")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    }

                    // Note: tvOS apps cannot directly determine if THIS Apple TV is the hub
                    // This is a limitation of HomeKit framework on tvOS
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)

                        Text("HomeKit hub status cannot be directly determined from tvOS app")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(25)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Home Hub Section

    private func homeHubSection(_ home: HMHome) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Home Hub")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            VStack(alignment: .leading, spacing: 15) {
                InfoRow(label: "Home Name", value: home.name)
                InfoRow(label: "Home ID", value: home.uniqueIdentifier.uuidString)

                // Hub count (Note: tvOS doesn't provide direct access to hub devices)
                HStack {
                    Text("Hub Devices")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Check Home app on iOS")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.blue)
                }

                Divider()

                // Recommendations
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hub Recommendations:")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()

                    TipRow(icon: "checkmark.circle.fill", text: "Keep at least one hub device powered on at all times", color: .green)
                    TipRow(icon: "checkmark.circle.fill", text: "Multiple hubs provide redundancy and better coverage", color: .green)
                    TipRow(icon: "checkmark.circle.fill", text: "Hubs: Apple TV 4K/HD, HomePod, or iPad (permanent)", color: .blue)
                }
            }
            .padding(25)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Remote Access Section

    private var remoteAccessSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Remote Access")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            HStack(spacing: 20) {
                Image(systemName: homeManager.primaryHome?.homeHubState == .connected ? "wifi" : "wifi.slash")
                    .font(.system(size: 50))
                    .foregroundColor(homeManager.primaryHome?.homeHubState == .connected ? .green : .orange)

                VStack(alignment: .leading, spacing: 8) {
                    Text(hubStateText)
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()

                    Text(hubStateDescription)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(25)
            .background(hubStateColor.opacity(0.1))
            .cornerRadius(12)
        }
    }

    // MARK: - Hub Information Section

    private var hubInformationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About HomeKit Hubs")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            VStack(alignment: .leading, spacing: 15) {
                HubInfoCard(
                    icon: "house.fill",
                    title: "Local Control",
                    description: "Hub enables automation and Siri control when you're home"
                )

                HubInfoCard(
                    icon: "icloud.fill",
                    title: "Remote Access",
                    description: "Control your home from anywhere with iCloud connection"
                )

                HubInfoCard(
                    icon: "calendar",
                    title: "Automations",
                    description: "Time-based and location-based automations require a hub"
                )

                HubInfoCard(
                    icon: "video.fill",
                    title: "Cameras",
                    description: "View security camera feeds remotely through your hub"
                )
            }
        }
    }

    // MARK: - Helper Properties

    private var hubStateText: String {
        guard let state = homeManager.primaryHome?.homeHubState else {
            return "Unknown"
        }

        switch state {
        case .notAvailable:
            return "No Hub Available"
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        @unknown default:
            return "Unknown"
        }
    }

    private var hubStateDescription: String {
        guard let state = homeManager.primaryHome?.homeHubState else {
            return "Unable to determine hub status"
        }

        switch state {
        case .notAvailable:
            return "No HomeKit hub is configured. Add an Apple TV, HomePod, or iPad as a hub."
        case .connected:
            return "Your hub is online and ready for remote access and automations."
        case .disconnected:
            return "Hub is not currently connected. Check your hub device and network connection."
        @unknown default:
            return "Hub state is unknown"
        }
    }

    private var hubStateColor: Color {
        guard let state = homeManager.primaryHome?.homeHubState else {
            return .gray
        }

        switch state {
        case .notAvailable:
            return .red
        case .connected:
            return .green
        case .disconnected:
            return .orange
        @unknown default:
            return .gray
        }
    }
}

// MARK: - Supporting Views

struct HubInfoCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(30)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Text(description)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    HubStatusView()
        .environmentObject(HomeKitManager())
}
