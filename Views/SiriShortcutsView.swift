import SwiftUI
import HomeKit

/// Siri Shortcuts management view
///
/// Features:
/// - Create custom Siri shortcuts for scenes and accessories
/// - Voice command examples
/// - Shortcut management
/// - "Hey Siri" suggestions
struct SiriShortcutsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var shortcutsManager = SiriShortcutsManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Siri Shortcuts")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Suggested Shortcuts
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Suggested Shortcuts")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 15) {
                            SiriShortcutCard(
                                phrase: "Good morning",
                                action: "Execute 'Good Morning' scene",
                                icon: "sunrise.fill",
                                color: .orange
                            )

                            SiriShortcutCard(
                                phrase: "I'm leaving",
                                action: "Turn off all lights and lock doors",
                                icon: "figure.walk",
                                color: .blue
                            )

                            SiriShortcutCard(
                                phrase: "Movie time",
                                action: "Dim lights and close blinds",
                                icon: "tv.fill",
                                color: .purple
                            )

                            SiriShortcutCard(
                                phrase: "Goodnight",
                                action: "Execute 'Good Night' scene",
                                icon: "moon.stars.fill",
                                color: .indigo
                            )
                        }
                        .padding(.horizontal, 80)
                    }

                    // Scene Shortcuts
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Scene Shortcuts")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        ForEach(homeManager.scenes, id: \.uniqueIdentifier) { scene in
                            SceneShortcutRow(scene: scene)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Voice Command Examples
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Voice Command Examples")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(alignment: .leading, spacing: 15) {
                            VoiceCommandExample(command: "Hey Siri, turn on the living room lights")
                            VoiceCommandExample(command: "Hey Siri, set the temperature to 72 degrees")
                            VoiceCommandExample(command: "Hey Siri, lock the front door")
                            VoiceCommandExample(command: "Hey Siri, show me the front door camera")
                            VoiceCommandExample(command: "Hey Siri, turn off all the lights")
                        }
                        .padding(25)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }

                    // Tips
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tips")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(alignment: .leading, spacing: 15) {
                            Text("Use clear, simple phrases like:")
                                .font(.body)
                                .foregroundColor(.secondary)

                            BulletPoint(text: "Use device names exactly as configured")
                            BulletPoint(text: "Include room names for clarity")
                            BulletPoint(text: "Combine multiple actions in scenes")
                            BulletPoint(text: "Practice your phrase for best recognition")
                        }
                        .padding(25)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// Siri shortcut card
struct SiriShortcutCard: View {
    let phrase: String
    let action: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.caption)
                    Text("\"Hey Siri, \(phrase)\"")
                        .font(.title3)
                        .bold()
                }

                Text(action)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                // Add to Siri
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add")
                }
                .font(.body)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Scene shortcut row
struct SceneShortcutRow: View {
    let scene: HMActionSet

    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.system(size: 30))
                .foregroundColor(.orange)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(scene.name)
                    .font(.title3)
                    .bold()

                Text("\"Hey Siri, activate \(scene.name)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                // Add to Siri
            }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

/// Voice command example
struct VoiceCommandExample: View {
    let command: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 25))
                .foregroundColor(.blue)

            Text(command)
                .font(.body)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

// MARK: - Siri Shortcuts Manager

/// Manager for Siri shortcuts
class SiriShortcutsManager: ObservableObject {
    static let shared = SiriShortcutsManager()

    @Published var customShortcuts: [CustomShortcut] = []

    private init() {
        loadShortcuts()
    }

    func createShortcut(phrase: String, action: ShortcutAction) {
        let shortcut = CustomShortcut(phrase: phrase, action: action)
        customShortcuts.append(shortcut)
        saveShortcuts()
    }

    func deleteShortcut(_ shortcut: CustomShortcut) {
        customShortcuts.removeAll { $0.id == shortcut.id }
        saveShortcuts()
    }

    private func loadShortcuts() {
        if let data = UserDefaults.standard.data(forKey: "siriShortcuts"),
           let shortcuts = try? JSONDecoder().decode([CustomShortcut].self, from: data) {
            customShortcuts = shortcuts
        }
    }

    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(customShortcuts) {
            UserDefaults.standard.set(data, forKey: "siriShortcuts")
        }
    }
}

/// Custom shortcut model
struct CustomShortcut: Identifiable, Codable {
    let id: UUID
    let phrase: String
    let action: ShortcutAction
    let createdAt: Date

    init(phrase: String, action: ShortcutAction) {
        self.id = UUID()
        self.phrase = phrase
        self.action = action
        self.createdAt = Date()
    }
}

/// Shortcut action types
enum ShortcutAction: Codable {
    case executeScene(String)
    case toggleAccessory(String)
    case setTemperature(Int)
    case custom(String)
}

#Preview {
    SiriShortcutsView()
        .environmentObject(HomeKitManager())
}
