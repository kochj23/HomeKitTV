import SwiftUI
import HomeKit

/// Settings and preferences view
struct SettingsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject var settings = Settings.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Settings")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Home Selection
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Home")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 15) {
                            ForEach(homeManager.homes, id: \.uniqueIdentifier) { home in
                                Button(action: {
                                    homeManager.switchHome(home)
                                }) {
                                    HStack {
                                        Image(systemName: "house.fill")
                                            .font(.system(size: 30))
                                        Text(home.name)
                                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                        Spacer()
                                        if home.uniqueIdentifier == homeManager.currentHome?.uniqueIdentifier {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.system(size: 30))
                                        }
                                    }
                                    .padding(25)
                                    .background(home.uniqueIdentifier == homeManager.currentHome?.uniqueIdentifier ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                                    .cornerRadius(15)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 80)
                    }

                    // Display Preferences
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Display")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 20) {
                            // Font Size Picker
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "textformat.size")
                                        .font(.system(size: 25))
                                    Text("Font Size")
                                        .font(.system(size: 18, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }

                                HStack(spacing: 20) {
                                    ForEach(FontSize.allCases) { size in
                                        Button(action: {
                                            settings.fontSizeMultiplier = size.multiplier
                                        }) {
                                            Text(size.rawValue)
                                                .font(.system(size: 18, weight: .bold))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                                .padding(.horizontal, 25)
                                                .padding(.vertical, 12)
                                                .background(FontSize.from(multiplier: settings.fontSizeMultiplier) == size ? Color.blue : Color.gray.opacity(0.2))
                                                .foregroundColor(FontSize.from(multiplier: settings.fontSizeMultiplier) == size ? .white : .primary)
                                                .cornerRadius(10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)

                            Toggle(isOn: $settings.showBatteryLevels) {
                                HStack {
                                    Image(systemName: "battery.100")
                                        .font(.system(size: 25))
                                    Text("Show Battery Levels")
                                        .font(.system(size: 18, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)

                            Toggle(isOn: $settings.showReachabilityIndicators) {
                                HStack {
                                    Image(systemName: "wifi")
                                        .font(.system(size: 25))
                                    Text("Show Reachability Indicators")
                                        .font(.system(size: 18, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Filtering Preferences
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Filtering")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 20) {
                            Toggle(isOn: $settings.hideUnreachableAccessories) {
                                HStack {
                                    Image(systemName: "wifi.slash")
                                        .font(.system(size: 25))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Hide Unreachable Accessories")
                                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                        Text("Accessories that are offline will not be shown")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)

                            Toggle(isOn: $settings.hideEmptyRooms) {
                                HStack {
                                    Image(systemName: "door.left.hand.closed")
                                        .font(.system(size: 25))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Hide Empty Rooms")
                                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                        Text("Rooms with no accessories will not be shown")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)

                            Toggle(isOn: $settings.hideEmptyScenes) {
                                HStack {
                                    Image(systemName: "lightbulb.slash")
                                        .font(.system(size: 25))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Hide Empty Scenes")
                                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                        Text("Scenes with no actions will not be shown")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Timing Preferences
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Timing")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 25))
                                    Text("Status Message Duration: \(Int(settings.statusMessageDuration))s")
                                        .font(.system(size: 18, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }

                                HStack(spacing: 30) {
                                    Button(action: {
                                        settings.statusMessageDuration = max(1, settings.statusMessageDuration - 0.5)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 40))
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(String(format: "%.1f", settings.statusMessageDuration))s")
                                        .font(.system(size: 30, weight: .bold))
                                        .frame(minWidth: 100)

                                    Button(action: {
                                        settings.statusMessageDuration = min(10, settings.statusMessageDuration + 0.5)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 40))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)

                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 25))
                                    Text("Auto-Refresh Interval: \(settings.autoRefreshInterval == 0 ? "Disabled" : "\(Int(settings.autoRefreshInterval))s")")
                                        .font(.system(size: 18, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }

                                HStack(spacing: 20) {
                                    Button(action: {
                                        settings.autoRefreshInterval = 0
                                    }) {
                                        Text("Off")
                                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .padding(.horizontal, 25)
                                            .padding(.vertical, 12)
                                            .background(settings.autoRefreshInterval == 0 ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(settings.autoRefreshInterval == 0 ? .white : .primary)
                                            .cornerRadius(10)
                                    }
                                    .buttonStyle(.plain)

                                    ForEach([30.0, 60.0, 300.0], id: \.self) { interval in
                                        Button(action: {
                                            settings.autoRefreshInterval = interval
                                        }) {
                                            Text("\(Int(interval))s")
                                                .font(.system(size: 18, weight: .bold))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                                .padding(.horizontal, 25)
                                                .padding(.vertical, 12)
                                                .background(settings.autoRefreshInterval == interval ? Color.blue : Color.gray.opacity(0.2))
                                                .foregroundColor(settings.autoRefreshInterval == interval ? .white : .primary)
                                                .cornerRadius(10)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 80)
                    }

                    // About
                    VStack(alignment: .leading, spacing: 20) {
                        Text("About")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Text("Version")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                                Text("2.0.0")
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            Divider()

                            HStack {
                                Text("Build")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                                Text("1")
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            Divider()

                            HStack {
                                Text("Accessories")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                                Text("\(homeManager.accessories.count)")
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }

                            Divider()

                            HStack {
                                Text("Scenes")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                                Text("\(homeManager.scenes.count)")
                                    .font(.system(size: 18, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        }
                        .padding(30)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }

                    // Done Button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.blue)
                            .cornerRadius(15)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 80)
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(HomeKitManager())
}
