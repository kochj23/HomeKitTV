import SwiftUI
import HomeKit

/// Adaptive lighting configuration and control view
struct AdaptiveLightingView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var adaptiveManager = AdaptiveLightingManager.shared

    var compatibleLights: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == HMServiceTypeLightbulb &&
                service.characteristics.contains { $0.characteristicType == HMCharacteristicTypeColorTemperature }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Adaptive Lighting")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Toggle(isOn: $adaptiveManager.isEnabled) {
                            Text("")
                        }
                        .onChange(of: adaptiveManager.isEnabled) { newValue in
                            if newValue {
                                adaptiveManager.applyToAllLights(homeManager: homeManager)
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    // Explanation
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(spacing: 15) {
                            Image(systemName: "sun.and.horizon.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Circadian Rhythm Lighting")
                                    .font(.title3)
                                    .bold()

                                Text("Automatically adjust color temperature throughout the day to match natural light")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(25)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)

                    // Current Color Temperature
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Current Setting")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        let currentTemp = adaptiveManager.calculateColorTemperature()
                        let kelvin = 1000000 / currentTemp

                        VStack(spacing: 20) {
                            // Color temperature visualization
                            Rectangle()
                                .fill(colorForTemperature(currentTemp))
                                .frame(height: 100)
                                .cornerRadius(15)
                                .overlay(
                                    Text("\(kelvin)K")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                )

                            Text(descriptionForTemperature(currentTemp))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Schedule Timeline
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Daily Schedule")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 15) {
                            ScheduleTimelineRow(time: "6:00 AM", temp: 350, label: "Sunrise", icon: "sunrise.fill")
                            ScheduleTimelineRow(time: "12:00 PM", temp: 140, label: "Noon", icon: "sun.max.fill")
                            ScheduleTimelineRow(time: "8:00 PM", temp: 400, label: "Sunset", icon: "sunset.fill")
                            ScheduleTimelineRow(time: "10:00 PM", temp: 500, label: "Night", icon: "moon.stars.fill")
                        }
                        .padding(.horizontal, 80)
                    }

                    // Compatible Lights
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Compatible Lights (\(compatibleLights.count))")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        if compatibleLights.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "lightbulb.slash")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No compatible lights found")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Text("Adaptive lighting requires lights with color temperature control")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else {
                            ForEach(compatibleLights, id: \.uniqueIdentifier) { light in
                                AdaptiveLightRow(light: light)
                            }
                            .padding(.horizontal, 80)
                        }
                    }

                    // Apply Now Button
                    if adaptiveManager.isEnabled {
                        Button(action: {
                            adaptiveManager.applyToAllLights(homeManager: homeManager)
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Apply Now")
                            }
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    func colorForTemperature(_ mireds: Int) -> Color {
        let kelvin = 1000000 / mireds

        if kelvin < 2500 {
            return Color(red: 1.0, green: 0.6, blue: 0.2) // Warm orange
        } else if kelvin < 4000 {
            return Color(red: 1.0, green: 0.85, blue: 0.7) // Soft white
        } else {
            return Color(red: 0.8, green: 0.9, blue: 1.0) // Cool white/blue
        }
    }

    func descriptionForTemperature(_ mireds: Int) -> String {
        let kelvin = 1000000 / mireds

        if kelvin < 2500 {
            return "Warm White - Relaxing evening light"
        } else if kelvin < 4000 {
            return "Soft White - Comfortable ambient light"
        } else {
            return "Cool White - Energizing daylight"
        }
    }
}

struct ScheduleTimelineRow: View {
    let time: String
    let temp: Int
    let label: String
    let icon: String

    var kelvin: Int {
        1000000 / temp
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.orange)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.body)
                    .bold()
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(kelvin)K")
                .font(.body)
                .monospaced()
                .foregroundColor(.secondary)
        }
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct AdaptiveLightRow: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var adaptiveManager = AdaptiveLightingManager.shared
    let light: HMAccessory

    var hasOverride: Bool {
        adaptiveManager.isOverrideActive(for: light)
    }

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 25))
                .foregroundColor(.yellow)
                .frame(width: 40)

            Text(light.name)
                .font(.body)

            Spacer()

            if hasOverride {
                Text("Override Active")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(6)

                Button(action: {
                    adaptiveManager.clearOverride(for: light)
                }) {
                    Text("Clear")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

#Preview {
    AdaptiveLightingView()
        .environmentObject(HomeKitManager())
}
