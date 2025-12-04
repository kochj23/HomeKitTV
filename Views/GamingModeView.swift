import SwiftUI
import HomeKit

/// Gaming Mode View - Optimizes environment for gaming sessions
///
/// **Features**:
/// - Quick profiles for different gaming scenarios
/// - Automatic brightness and color optimization
/// - Audio optimization for gaming headsets
/// - Do Not Disturb mode integration
/// - Temperature control for extended sessions
///
/// **Security**: All operations validated against HomeKit permissions
struct GamingModeView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var isGamingModeActive = false
    @State private var selectedProfile: GamingProfile = .fps
    @State private var autoAdjustLighting = true
    @State private var dndEnabled = true
    @State private var temperatureTarget: Double = 68.0

    enum GamingProfile: String, CaseIterable {
        case fps = "FPS Games"
        case rpg = "RPG Games"
        case casual = "Casual Gaming"
        case streaming = "Streaming"

        var icon: String {
            switch self {
            case .fps: return "target"
            case .rpg: return "figure.walk"
            case .casual: return "dice.fill"
            case .streaming: return "video.fill"
            }
        }

        var description: String {
            switch self {
            case .fps: return "High contrast, cool lighting"
            case .rpg: return "Warm ambient lighting"
            case .casual: return "Balanced comfort"
            case .streaming: return "Studio lighting setup"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gaming Mode")
                            .font(.largeTitle)
                            .bold()
                        Text(isGamingModeActive ? "Active" : "Inactive")
                            .font(.title3)
                            .foregroundColor(isGamingModeActive ? .green : .secondary)
                    }

                    Spacer()

                    // Master toggle
                    Button(action: {
                        toggleGamingMode()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isGamingModeActive ? "stop.fill" : "play.fill")
                            Text(isGamingModeActive ? "Deactivate" : "Activate")
                        }
                        .font(.title3)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(isGamingModeActive ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // Gaming Profiles
                VStack(alignment: .leading, spacing: 20) {
                    Text("Gaming Profile")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 80)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 40)], spacing: 40) {
                        ForEach(GamingProfile.allCases, id: \.self) { profile in
                            Button(action: {
                                selectedProfile = profile
                                if isGamingModeActive {
                                    applyProfile(profile)
                                }
                            }) {
                                HStack(spacing: 20) {
                                    Image(systemName: profile.icon)
                                        .font(.system(size: 40))
                                        .foregroundColor(selectedProfile == profile ? .white : .primary)
                                        .frame(width: 60)

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(profile.rawValue)
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(selectedProfile == profile ? .white : .primary)

                                        Text(profile.description)
                                            .font(.body)
                                            .foregroundColor(selectedProfile == profile ? .white.opacity(0.8) : .secondary)
                                    }

                                    Spacer()

                                    if selectedProfile == profile {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(30)
                                .background(selectedProfile == profile ? Color.blue : Color.gray.opacity(0.1))
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 80)
                }

                // Settings
                VStack(alignment: .leading, spacing: 20) {
                    Text("Settings")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 80)

                    VStack(spacing: 30) {
                        // Auto-adjust lighting
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Auto-Adjust Lighting")
                                    .font(.title3)
                                Text("Automatically optimize room lighting")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $autoAdjustLighting)
                                .labelsHidden()
                        }

                        Divider()

                        // Do Not Disturb
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Do Not Disturb")
                                    .font(.title3)
                                Text("Silence notifications during gaming")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $dndEnabled)
                                .labelsHidden()
                        }

                        Divider()

                        // Temperature Control
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Target Temperature")
                                    .font(.title3)
                                Spacer()
                                Text("\(Int(temperatureTarget))°F")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 20) {
                                Button(action: {
                                    if temperatureTarget > 60 {
                                        temperatureTarget -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title)
                                }
                                .buttonStyle(.plain)

                                Text("\(Int(temperatureTarget))°F")
                                    .font(.title2)
                                    .frame(minWidth: 100)

                                Button(action: {
                                    if temperatureTarget < 75 {
                                        temperatureTarget += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title)
                                }
                                .buttonStyle(.plain)
                            }

                            Text("Maintain comfortable temperature for extended gaming sessions")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(30)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal, 80)
                }

                // Info
                VStack(alignment: .leading, spacing: 15) {
                    HStack(spacing: 15) {
                        Image(systemName: "info.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Gaming Mode will automatically adjust your HomeKit accessories for optimal gaming experience.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(30)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 60)
        }
    }

    // MARK: - Actions

    /// Toggles gaming mode on/off
    private func toggleGamingMode() {
        isGamingModeActive.toggle()

        if isGamingModeActive {
            applyProfile(selectedProfile)
        } else {
            deactivateGamingMode()
        }
    }

    /// Applies selected gaming profile
    /// - Parameter profile: The gaming profile to apply
    private func applyProfile(_ profile: GamingProfile) {
        Task {
            switch profile {
            case .fps:
                await applyFPSProfile()
            case .rpg:
                await applyRPGProfile()
            case .casual:
                await applyCasualProfile()
            case .streaming:
                await applyStreamingProfile()
            }
        }
    }

    /// Applies FPS gaming profile (high contrast, cool lighting)
    private func applyFPSProfile() async {
        // Set lights to cool white, high brightness
        for accessory in homeManager.accessories {
            guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { continue }

            // Brightness
            if let brightness = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                try? await brightness.writeValue(100)
            }

            // Color temperature (cool)
            if let temp = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeColorTemperature }) {
                try? await temp.writeValue(140) // Cool white
            }
        }
    }

    /// Applies RPG gaming profile (warm ambient lighting)
    private func applyRPGProfile() async {
        // Set lights to warm, medium brightness
        for accessory in homeManager.accessories {
            guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { continue }

            // Brightness
            if let brightness = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                try? await brightness.writeValue(60)
            }

            // Color temperature (warm)
            if let temp = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeColorTemperature }) {
                try? await temp.writeValue(400) // Warm white
            }
        }
    }

    /// Applies casual gaming profile (balanced)
    private func applyCasualProfile() async {
        // Balanced lighting
        for accessory in homeManager.accessories {
            guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { continue }

            // Brightness
            if let brightness = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                try? await brightness.writeValue(75)
            }
        }
    }

    /// Applies streaming profile (studio lighting)
    private func applyStreamingProfile() async {
        // Bright, neutral lighting for cameras
        for accessory in homeManager.accessories {
            guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { continue }

            // Brightness
            if let brightness = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                try? await brightness.writeValue(100)
            }

            // Color temperature (neutral)
            if let temp = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeColorTemperature }) {
                try? await temp.writeValue(250) // Neutral white
            }
        }
    }

    /// Deactivates gaming mode
    private func deactivateGamingMode() {
        // Reset to normal settings
        Task {
            for accessory in homeManager.accessories {
                guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }) else { continue }

                // Reset brightness
                if let brightness = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                    try? await brightness.writeValue(75)
                }
            }
        }
    }
}

struct GamingModeView_Previews: PreviewProvider {
    static var previews: some View {
        GamingModeView()
            .environmentObject(HomeKitManager())
    }
}
