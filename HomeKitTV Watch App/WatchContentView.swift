//
//  WatchContentView.swift
//  HomeKitTV Watch App
//
//  Main watch interface with tabs for scenes and accessories
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import SwiftUI
import WatchKit

struct WatchContentView: View {
    @EnvironmentObject var dataStore: WatchDataStore
    @EnvironmentObject var connectivity: WatchPhoneConnectivity

    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            if dataStore.favoriteScenes.isEmpty && dataStore.favoriteAccessories.isEmpty && dataStore.lastUpdated == nil {
                emptyStateView
            } else {
                TabView(selection: $selectedTab) {
                    FavoriteScenesView()
                        .tag(0)

                    FavoriteAccessoriesView()
                        .tag(1)

                    WatchSettingsView()
                        .tag(2)
                }
                .tabViewStyle(.page)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "house.fill")
                .font(.system(size: 40))
                .foregroundColor(.cyan)

            Text("HomeKitTV")
                .font(.headline)

            if connectivity.isReachable {
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView()
                    .padding(.top, 8)
            } else {
                Text("Open HomeKitTV on your iPhone to sync")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    connectivity.requestSync()
                } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - Favorite Scenes View

struct FavoriteScenesView: View {
    @EnvironmentObject var dataStore: WatchDataStore
    @EnvironmentObject var connectivity: WatchPhoneConnectivity

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.purple)
                    Text("Scenes")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)

                if dataStore.favoriteScenes.isEmpty {
                    emptyView
                } else {
                    ForEach(dataStore.favoriteScenes) { scene in
                        SceneButton(scene: scene)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Scenes")
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No favorite scenes")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Add favorites in HomeKitTV")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Scene Button

struct SceneButton: View {
    let scene: WatchScene
    @EnvironmentObject var connectivity: WatchPhoneConnectivity
    @State private var isPressed = false

    var body: some View {
        Button {
            connectivity.executeScene(id: scene.id)
            isPressed = true

            // Reset after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPressed = false
            }
        } label: {
            HStack {
                Image(systemName: scene.iconName ?? "sparkles")
                    .font(.title3)
                    .foregroundColor(.purple)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(scene.name)
                        .font(.system(.body, design: .rounded))
                        .lineLimit(1)

                    Text("\(scene.accessoryCount) accessories")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(isPressed ? 0.3 : 0.15))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

// MARK: - Favorite Accessories View

struct FavoriteAccessoriesView: View {
    @EnvironmentObject var dataStore: WatchDataStore
    @EnvironmentObject var connectivity: WatchPhoneConnectivity

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Accessories")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)

                if dataStore.favoriteAccessories.isEmpty {
                    emptyView
                } else {
                    ForEach(dataStore.favoriteAccessories) { accessory in
                        AccessoryRow(accessory: accessory)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Devices")
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("No favorite devices")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Add favorites in HomeKitTV")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Accessory Row

struct AccessoryRow: View {
    let accessory: WatchAccessory
    @EnvironmentObject var connectivity: WatchPhoneConnectivity
    @State private var brightness: Double = 50

    var body: some View {
        VStack(spacing: 4) {
            Button {
                connectivity.toggleAccessory(id: accessory.id)
            } label: {
                HStack {
                    // Icon
                    Image(systemName: iconForCategory(accessory.categoryType))
                        .font(.title3)
                        .foregroundColor(accessory.isOn == true ? categoryColor : .secondary)
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(accessory.name)
                            .font(.system(.body, design: .rounded))
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            if let roomName = accessory.roomName {
                                Text(roomName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            if !accessory.isReachable {
                                Image(systemName: "wifi.slash")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    Spacer()

                    // State indicator
                    stateIndicator
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(accessory.isOn == true ? categoryColor.opacity(0.2) : Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            .disabled(!accessory.isReachable)
            .opacity(accessory.isReachable ? 1.0 : 0.5)

            // Brightness slider for lights
            if accessory.categoryType == "light" && accessory.brightness != nil && accessory.isOn == true {
                Slider(value: Binding(
                    get: { Double(accessory.brightness ?? 50) },
                    set: { newValue in
                        connectivity.setAccessoryBrightness(id: accessory.id, brightness: Int(newValue))
                    }
                ), in: 1...100, step: 5)
                .tint(.yellow)
                .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal)
    }

    private var categoryColor: Color {
        switch accessory.categoryType {
        case "light": return .yellow
        case "outlet": return .orange
        case "switch": return .blue
        case "thermostat": return .cyan
        case "fan": return .mint
        case "lock": return .red
        case "sensor": return .green
        default: return .gray
        }
    }

    @ViewBuilder
    private var stateIndicator: some View {
        if let isOn = accessory.isOn {
            Circle()
                .fill(isOn ? Color.green : Color.secondary.opacity(0.3))
                .frame(width: 10, height: 10)
        } else if let temp = accessory.temperature {
            Text("\(Int(temp))°")
                .font(.caption)
                .foregroundColor(.cyan)
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "light": return "lightbulb.fill"
        case "outlet": return "poweroutlet.type.b.fill"
        case "switch": return "switch.2"
        case "thermostat": return "thermometer"
        case "fan": return "fan.fill"
        case "lock": return "lock.fill"
        case "sensor": return "sensor.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Watch Settings View

struct WatchSettingsView: View {
    @EnvironmentObject var dataStore: WatchDataStore
    @EnvironmentObject var connectivity: WatchPhoneConnectivity

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                    Text("Settings")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)

                // Connection status
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connection")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Circle()
                            .fill(connectivity.isReachable ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)

                        Text(connectivity.isReachable ? "Connected" : "Waiting for iPhone")
                            .font(.caption2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Sync info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("Last synced:")
                            .font(.caption2)
                        Spacer()
                        Text(dataStore.lastUpdatedFormatted)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Scenes:")
                            .font(.caption2)
                        Spacer()
                        Text("\(dataStore.favoriteScenes.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Devices:")
                            .font(.caption2)
                        Spacer()
                        Text("\(dataStore.favoriteAccessories.count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                // Sync button
                Button {
                    connectivity.requestSync()
                } label: {
                    Label("Sync Now", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(!connectivity.isReachable)

                // Error display
                if let error = dataStore.lastError {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchDataStore.shared)
        .environmentObject(WatchPhoneConnectivity.shared)
}
