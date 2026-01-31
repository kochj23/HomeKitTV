//
//  HomeKitLiveActivity.swift
//  HomeKitTV
//
//  Live Activity for real-time HomeKit status on lock screen
//  Shows scene execution status, accessory states, and alerts
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Attributes

struct HomeKitActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that can be updated
        var currentScene: String?
        var sceneProgress: Double // 0.0 to 1.0
        var activeAccessories: Int
        var totalAccessories: Int
        var alertMessage: String?
        var isExecuting: Bool
    }

    // Fixed attributes that don't change during the activity
    var homeName: String
    var activityType: ActivityType

    enum ActivityType: String, Codable {
        case sceneExecution
        case accessoryControl
        case homeMonitoring
    }
}

// MARK: - Live Activity Widget

struct HomeKitLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HomeKitActivityAttributes.self) { context in
            // Lock screen presentation
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "house.fill")
                            .foregroundColor(.cyan)
                        Text(context.attributes.homeName)
                            .font(.caption.bold())
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isExecuting {
                        ProgressView(value: context.state.sceneProgress)
                            .progressViewStyle(.circular)
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    if let scene = context.state.currentScene {
                        Text(scene)
                            .font(.headline)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("\(context.state.activeAccessories)/\(context.state.totalAccessories)", systemImage: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)

                        if let alert = context.state.alertMessage {
                            Spacer()
                            Text(alert)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "house.fill")
                    .foregroundColor(.cyan)
            } compactTrailing: {
                if context.state.isExecuting {
                    ProgressView(value: context.state.sceneProgress)
                        .progressViewStyle(.circular)
                        .scaleEffect(0.5)
                } else {
                    Text("\(context.state.activeAccessories)")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            } minimal: {
                Image(systemName: "house.fill")
                    .foregroundColor(.cyan)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<HomeKitActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Home icon
            VStack {
                Image(systemName: "house.fill")
                    .font(.title)
                    .foregroundColor(.cyan)
                Text(context.attributes.homeName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)

            // Status
            VStack(alignment: .leading, spacing: 4) {
                if let scene = context.state.currentScene {
                    HStack {
                        Text(scene)
                            .font(.headline.bold())

                        if context.state.isExecuting {
                            Spacer()
                            ProgressView(value: context.state.sceneProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 60)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Label("\(context.state.activeAccessories) on", systemImage: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)

                    Text("\(context.state.totalAccessories) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let alert = context.state.alertMessage {
                    Text(alert)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Action button
            if context.state.isExecuting {
                Button(intent: CancelSceneIntent()) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
    }
}

// MARK: - Cancel Scene Intent

struct CancelSceneIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel Scene"

    func perform() async throws -> some IntentResult {
        NotificationCenter.default.post(name: .cancelSceneFromLiveActivity, object: nil)
        return .result()
    }
}

// MARK: - Live Activity Manager

@MainActor
class HomeKitLiveActivityManager {
    static let shared = HomeKitLiveActivityManager()

    private var currentActivity: Activity<HomeKitActivityAttributes>?

    private init() {}

    // Start a scene execution activity
    func startSceneExecution(homeName: String, sceneName: String, totalAccessories: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not enabled")
            return
        }

        let attributes = HomeKitActivityAttributes(
            homeName: homeName,
            activityType: .sceneExecution
        )

        let initialState = HomeKitActivityAttributes.ContentState(
            currentScene: sceneName,
            sceneProgress: 0.0,
            activeAccessories: 0,
            totalAccessories: totalAccessories,
            alertMessage: nil,
            isExecuting: true
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    // Update scene progress
    func updateSceneProgress(_ progress: Double, activeAccessories: Int) async {
        guard let activity = currentActivity else { return }

        let updatedState = HomeKitActivityAttributes.ContentState(
            currentScene: activity.content.state.currentScene,
            sceneProgress: progress,
            activeAccessories: activeAccessories,
            totalAccessories: activity.content.state.totalAccessories,
            alertMessage: nil,
            isExecuting: progress < 1.0
        )

        await activity.update(
            ActivityContent(state: updatedState, staleDate: nil)
        )
    }

    // Complete scene execution
    func completeSceneExecution(activeAccessories: Int) async {
        guard let activity = currentActivity else { return }

        let finalState = HomeKitActivityAttributes.ContentState(
            currentScene: activity.content.state.currentScene,
            sceneProgress: 1.0,
            activeAccessories: activeAccessories,
            totalAccessories: activity.content.state.totalAccessories,
            alertMessage: "Scene complete",
            isExecuting: false
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(.now + 5)
        )

        currentActivity = nil
    }

    // Start home monitoring activity
    func startHomeMonitoring(homeName: String, activeAccessories: Int, totalAccessories: Int) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = HomeKitActivityAttributes(
            homeName: homeName,
            activityType: .homeMonitoring
        )

        let initialState = HomeKitActivityAttributes.ContentState(
            currentScene: "Monitoring",
            sceneProgress: 0.0,
            activeAccessories: activeAccessories,
            totalAccessories: totalAccessories,
            alertMessage: nil,
            isExecuting: false
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Failed to start monitoring activity: \(error)")
        }
    }

    // Update monitoring state
    func updateMonitoringState(activeAccessories: Int, alert: String? = nil) async {
        guard let activity = currentActivity else { return }

        let updatedState = HomeKitActivityAttributes.ContentState(
            currentScene: "Monitoring",
            sceneProgress: 0.0,
            activeAccessories: activeAccessories,
            totalAccessories: activity.content.state.totalAccessories,
            alertMessage: alert,
            isExecuting: false
        )

        await activity.update(
            ActivityContent(state: updatedState, staleDate: nil)
        )
    }

    // End all activities
    func endAllActivities() async {
        for activity in Activity<HomeKitActivityAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let cancelSceneFromLiveActivity = Notification.Name("cancelSceneFromLiveActivity")
}
#endif
