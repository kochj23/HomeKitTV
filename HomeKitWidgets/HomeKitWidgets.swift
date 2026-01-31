//
//  HomeKitWidgets.swift
//  HomeKitTV Widgets
//
//  WidgetKit widgets for quick HomeKit access
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry

struct HomeKitWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: HomeKitWidgetConfiguration

    // Data from app
    let favoriteScenes: [WidgetScene]
    let favoriteAccessories: [WidgetAccessory]
    let homeName: String
    let lastUpdated: Date?
}

struct WidgetScene: Identifiable, Codable {
    let id: String
    let name: String
    let iconName: String
    let accessoryCount: Int
}

struct WidgetAccessory: Identifiable, Codable {
    let id: String
    let name: String
    let roomName: String?
    let categoryType: String
    let isOn: Bool
    let brightness: Int?
    let temperature: Double?
}

// MARK: - Configuration

struct HomeKitWidgetConfiguration: AppIntentTimelineConfiguration {
    static var displayName = "HomeKit"
    static var description = IntentDescription("Quick access to your smart home")
}

// MARK: - Timeline Provider

struct HomeKitWidgetProvider: AppIntentTimelineProvider {
    typealias Entry = HomeKitWidgetEntry
    typealias Intent = HomeKitWidgetConfiguration

    func placeholder(in context: Context) -> HomeKitWidgetEntry {
        HomeKitWidgetEntry(
            date: Date(),
            configuration: HomeKitWidgetConfiguration(),
            favoriteScenes: [
                WidgetScene(id: "1", name: "Good Morning", iconName: "sunrise.fill", accessoryCount: 5),
                WidgetScene(id: "2", name: "Movie Time", iconName: "tv.fill", accessoryCount: 3),
                WidgetScene(id: "3", name: "Good Night", iconName: "moon.stars.fill", accessoryCount: 4)
            ],
            favoriteAccessories: [
                WidgetAccessory(id: "1", name: "Living Room", roomName: "Living Room", categoryType: "light", isOn: true, brightness: 80, temperature: nil),
                WidgetAccessory(id: "2", name: "Thermostat", roomName: "Hallway", categoryType: "thermostat", isOn: true, brightness: nil, temperature: 72)
            ],
            homeName: "Home",
            lastUpdated: Date()
        )
    }

    func snapshot(for configuration: HomeKitWidgetConfiguration, in context: Context) async -> HomeKitWidgetEntry {
        await getEntry(for: configuration)
    }

    func timeline(for configuration: HomeKitWidgetConfiguration, in context: Context) async -> Timeline<HomeKitWidgetEntry> {
        let entry = await getEntry(for: configuration)

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func getEntry(for configuration: HomeKitWidgetConfiguration) async -> HomeKitWidgetEntry {
        // Load data from shared container
        let data = WidgetDataStore.shared.loadData()

        return HomeKitWidgetEntry(
            date: Date(),
            configuration: configuration,
            favoriteScenes: data.scenes,
            favoriteAccessories: data.accessories,
            homeName: data.homeName,
            lastUpdated: data.lastUpdated
        )
    }
}

// MARK: - Widget Data Store (Shared with main app)

class WidgetDataStore {
    static let shared = WidgetDataStore()

    private let suiteName = "group.com.jordankoch.HomeKitTV"
    private let dataKey = "widgetData"

    struct WidgetData: Codable {
        let homeName: String
        let scenes: [WidgetScene]
        let accessories: [WidgetAccessory]
        let lastUpdated: Date?
    }

    func loadData() -> WidgetData {
        guard let userDefaults = UserDefaults(suiteName: suiteName),
              let data = userDefaults.data(forKey: dataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return WidgetData(homeName: "Home", scenes: [], accessories: [], lastUpdated: nil)
        }
        return widgetData
    }

    func saveData(_ data: WidgetData) {
        guard let userDefaults = UserDefaults(suiteName: suiteName),
              let encoded = try? JSONEncoder().encode(data) else { return }
        userDefaults.set(encoded, forKey: dataKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Scene Widget View

struct SceneWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: HomeKitWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallSceneWidget
        case .systemMedium:
            mediumSceneWidget
        case .systemLarge:
            largeSceneWidget
        case .accessoryCircular:
            circularWidget
        case .accessoryRectangular:
            rectangularWidget
        default:
            smallSceneWidget
        }
    }

    // MARK: - Small Widget (Single scene or home status)

    private var smallSceneWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "house.fill")
                    .font(.headline)
                    .foregroundColor(.cyan)
                Text(entry.homeName)
                    .font(.headline)
                    .lineLimit(1)
            }

            Spacer()

            if let firstScene = entry.favoriteScenes.first {
                Link(destination: URL(string: "homekittv://scene/\(firstScene.id)")!) {
                    HStack {
                        Image(systemName: firstScene.iconName)
                            .font(.title2)
                            .foregroundColor(.purple)

                        VStack(alignment: .leading) {
                            Text(firstScene.name)
                                .font(.subheadline.bold())
                                .lineLimit(1)
                            Text("Tap to run")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("No favorite scenes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Text("\(entry.favoriteScenes.count) scenes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(entry.favoriteAccessories.count) devices")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Medium Widget (Scene grid)

    private var mediumSceneWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.cyan)
                Text(entry.homeName)
                    .font(.headline)
                Spacer()
                Text("Scenes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if entry.favoriteScenes.isEmpty {
                Spacer()
                Text("Add favorite scenes in HomeKitTV")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(entry.favoriteScenes.prefix(4)) { scene in
                        Link(destination: URL(string: "homekittv://scene/\(scene.id)")!) {
                            SceneButton(scene: scene)
                        }
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Large Widget (Full dashboard)

    private var largeSceneWidget: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
                VStack(alignment: .leading) {
                    Text(entry.homeName)
                        .font(.headline)
                    if let lastUpdated = entry.lastUpdated {
                        Text("Updated \(lastUpdated, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            Divider()

            // Scenes section
            Text("Quick Scenes")
                .font(.subheadline.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(entry.favoriteScenes.prefix(4)) { scene in
                    Link(destination: URL(string: "homekittv://scene/\(scene.id)")!) {
                        SceneButton(scene: scene)
                    }
                }
            }

            Divider()

            // Accessories section
            Text("Favorite Devices")
                .font(.subheadline.bold())

            ForEach(entry.favoriteAccessories.prefix(3)) { accessory in
                AccessoryRow(accessory: accessory)
            }

            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    // MARK: - Lock Screen Widgets

    private var circularWidget: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 2) {
                Image(systemName: "house.fill")
                    .font(.title3)
                Text("\(entry.favoriteScenes.count)")
                    .font(.caption.bold())
            }
        }
    }

    private var rectangularWidget: some View {
        HStack {
            Image(systemName: "house.fill")
                .font(.title2)

            VStack(alignment: .leading) {
                Text(entry.homeName)
                    .font(.headline)
                Text("\(entry.favoriteScenes.count) scenes • \(entry.favoriteAccessories.count) devices")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Scene Button Component

struct SceneButton: View {
    let scene: WidgetScene

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: scene.iconName)
                .font(.body)
                .foregroundColor(.purple)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(scene.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                Text("\(scene.accessoryCount) devices")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color.purple.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Accessory Row Component

struct AccessoryRow: View {
    let accessory: WidgetAccessory

    var body: some View {
        HStack {
            Image(systemName: iconForCategory(accessory.categoryType))
                .font(.body)
                .foregroundColor(accessory.isOn ? categoryColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(accessory.name)
                    .font(.caption.bold())
                    .lineLimit(1)
                if let room = accessory.roomName {
                    Text(room)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Status
            if let brightness = accessory.brightness {
                Text("\(brightness)%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let temp = accessory.temperature {
                Text("\(Int(temp))°")
                    .font(.caption)
                    .foregroundColor(.cyan)
            } else {
                Circle()
                    .fill(accessory.isOn ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch accessory.categoryType {
        case "light": return .yellow
        case "outlet": return .orange
        case "thermostat": return .cyan
        case "fan": return .mint
        case "lock": return .red
        default: return .blue
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "light": return "lightbulb.fill"
        case "outlet": return "poweroutlet.type.b.fill"
        case "thermostat": return "thermometer"
        case "fan": return "fan.fill"
        case "lock": return "lock.fill"
        case "sensor": return "sensor.fill"
        default: return "questionmark.circle"
        }
    }
}

// MARK: - Widget Bundle

@main
struct HomeKitWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeKitSceneWidget()
        HomeKitAccessoryWidget()
    }
}

// MARK: - Scene Widget

struct HomeKitSceneWidget: Widget {
    let kind: String = "HomeKitSceneWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HomeKitWidgetConfiguration.self, provider: HomeKitWidgetProvider()) { entry in
            SceneWidgetView(entry: entry)
        }
        .configurationDisplayName("HomeKit Scenes")
        .description("Quick access to your favorite scenes")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

// MARK: - Accessory Widget

struct AccessoryWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: HomeKitWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallAccessoryWidget
        case .systemMedium:
            mediumAccessoryWidget
        default:
            smallAccessoryWidget
        }
    }

    private var smallAccessoryWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Devices")
                    .font(.headline)
            }

            Spacer()

            if let firstAccessory = entry.favoriteAccessories.first {
                VStack(alignment: .leading, spacing: 4) {
                    Text(firstAccessory.name)
                        .font(.subheadline.bold())

                    HStack {
                        Circle()
                            .fill(firstAccessory.isOn ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text(firstAccessory.isOn ? "On" : "Off")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let brightness = firstAccessory.brightness {
                            Text("• \(brightness)%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            Text("\(entry.favoriteAccessories.filter { $0.isOn }.count)/\(entry.favoriteAccessories.count) on")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var mediumAccessoryWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Favorite Devices")
                    .font(.headline)
                Spacer()
                Text("\(entry.favoriteAccessories.filter { $0.isOn }.count) on")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if entry.favoriteAccessories.isEmpty {
                Spacer()
                Text("Add favorite devices in HomeKitTV")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            } else {
                ForEach(entry.favoriteAccessories.prefix(3)) { accessory in
                    AccessoryRow(accessory: accessory)
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct HomeKitAccessoryWidget: Widget {
    let kind: String = "HomeKitAccessoryWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: HomeKitWidgetConfiguration.self, provider: HomeKitWidgetProvider()) { entry in
            AccessoryWidgetView(entry: entry)
        }
        .configurationDisplayName("HomeKit Devices")
        .description("Monitor your favorite devices")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
