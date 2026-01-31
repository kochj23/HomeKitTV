//
//  HomeKitComplications.swift
//  HomeKitTV Watch App
//
//  WidgetKit complications for Apple Watch faces
//  Supports various complication families for quick HomeKit access
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import WidgetKit
import SwiftUI

// MARK: - Complication Entry

struct HomeKitComplicationEntry: TimelineEntry {
    let date: Date
    let configuration: HomeKitComplicationConfiguration
    let favoriteSceneCount: Int
    let favoriteAccessoryCount: Int
    let firstSceneName: String?
    let firstAccessoryName: String?
    let isAccessoryOn: Bool?
}

// MARK: - Configuration Intent

struct HomeKitComplicationConfiguration {
    enum ComplicationType: String {
        case scene = "scene"
        case accessory = "accessory"
        case overview = "overview"
    }

    let type: ComplicationType
    let targetId: String?
    let targetName: String?

    static let `default` = HomeKitComplicationConfiguration(type: .overview, targetId: nil, targetName: nil)
}

// MARK: - Timeline Provider

struct HomeKitComplicationProvider: TimelineProvider {
    typealias Entry = HomeKitComplicationEntry

    func placeholder(in context: Context) -> HomeKitComplicationEntry {
        HomeKitComplicationEntry(
            date: Date(),
            configuration: .default,
            favoriteSceneCount: 3,
            favoriteAccessoryCount: 5,
            firstSceneName: "Good Night",
            firstAccessoryName: "Living Room",
            isAccessoryOn: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (HomeKitComplicationEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HomeKitComplicationEntry>) -> Void) {
        let entry = createEntry()

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

        completion(timeline)
    }

    private func createEntry() -> HomeKitComplicationEntry {
        let dataStore = WatchDataStore.shared

        return HomeKitComplicationEntry(
            date: Date(),
            configuration: .default,
            favoriteSceneCount: dataStore.favoriteScenes.count,
            favoriteAccessoryCount: dataStore.favoriteAccessories.count,
            firstSceneName: dataStore.favoriteScenes.first?.name,
            firstAccessoryName: dataStore.favoriteAccessories.first?.name,
            isAccessoryOn: dataStore.favoriteAccessories.first?.isOn
        )
    }
}

// MARK: - Complication Views

struct HomeKitComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: HomeKitComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryCorner:
            cornerView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            circularView
        }
    }

    // MARK: - Circular (Small round complication)

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)

                Text("\(entry.favoriteSceneCount + entry.favoriteAccessoryCount)")
                    .font(.system(size: 12, weight: .bold))
            }
        }
        .widgetURL(URL(string: "homekittv://open")!)
    }

    // MARK: - Corner (Shown in corner of watch face)

    private var cornerView: some View {
        ZStack {
            Image(systemName: "house.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.cyan)
        }
        .widgetLabel {
            Text("\(entry.favoriteSceneCount) scenes")
        }
    }

    // MARK: - Rectangular (Larger complication showing details)

    private var rectangularView: some View {
        HStack(spacing: 8) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: "house.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("HomeKitTV")
                    .font(.system(size: 14, weight: .semibold))

                HStack(spacing: 8) {
                    Label("\(entry.favoriteSceneCount)", systemImage: "wand.and.stars")
                        .font(.system(size: 11))
                        .foregroundColor(.purple)

                    Label("\(entry.favoriteAccessoryCount)", systemImage: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.yellow)
                }

                if let sceneName = entry.firstSceneName {
                    Text("Quick: \(sceneName)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .widgetURL(URL(string: "homekittv://open")!)
    }

    // MARK: - Inline (Single line text)

    private var inlineView: some View {
        Label("Home: \(entry.favoriteSceneCount) scenes", systemImage: "house.fill")
    }
}

// MARK: - Scene-Specific Complication

struct SceneComplicationView: View {
    let sceneName: String

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.purple)

                Text(sceneName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
            }
            .padding(4)
        }
    }
}

// MARK: - Accessory-Specific Complication

struct AccessoryComplicationView: View {
    let accessoryName: String
    let isOn: Bool

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isOn ? .yellow : .secondary)

                Text(accessoryName)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)

                Circle()
                    .fill(isOn ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
            .padding(4)
        }
    }
}

// MARK: - Widget Configuration

@main
struct HomeKitComplicationBundle: WidgetBundle {
    var body: some Widget {
        HomeKitOverviewComplication()
        HomeKitSceneComplication()
        HomeKitAccessoryComplication()
    }
}

// MARK: - Overview Complication Widget

struct HomeKitOverviewComplication: Widget {
    let kind: String = "HomeKitOverview"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeKitComplicationProvider()) { entry in
            HomeKitComplicationView(entry: entry)
        }
        .configurationDisplayName("HomeKit Overview")
        .description("Quick access to your smart home")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

// MARK: - Scene Complication Widget

struct HomeKitSceneComplication: Widget {
    let kind: String = "HomeKitScene"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeKitComplicationProvider()) { entry in
            if let sceneName = entry.firstSceneName {
                SceneComplicationView(sceneName: sceneName)
            } else {
                SceneComplicationView(sceneName: "No Scene")
            }
        }
        .configurationDisplayName("Quick Scene")
        .description("Execute your favorite scene")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}

// MARK: - Accessory Complication Widget

struct HomeKitAccessoryComplication: Widget {
    let kind: String = "HomeKitAccessory"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HomeKitComplicationProvider()) { entry in
            AccessoryComplicationView(
                accessoryName: entry.firstAccessoryName ?? "Device",
                isOn: entry.isAccessoryOn ?? false
            )
        }
        .configurationDisplayName("Quick Accessory")
        .description("Control your favorite device")
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}
