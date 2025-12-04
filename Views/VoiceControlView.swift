import SwiftUI
import HomeKit

/// Voice control management view
///
/// Displays voice command history, Siri shortcuts, and voice control settings.
///
/// **Features**:
/// - Voice command history with timestamps
/// - Siri shortcut suggestions
/// - Create custom voice commands
/// - Most used commands display
/// - Voice control statistics
struct VoiceControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var voiceManager = VoiceControlManager.shared
    @State private var showingShortcutBuilder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Voice Control")
                                .font(.largeTitle)
                                .bold()
                            Text("Siri shortcuts and voice commands")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            showingShortcutBuilder = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Shortcut")
                            }
                            .font(.title3)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    // Quick Stats
                    HStack(spacing: 30) {
                        VoiceStatCard(
                            icon: "mic.fill",
                            title: "Commands Today",
                            value: "\(voiceManager.voiceHistory.filter { Calendar.current.isDateInToday($0.timestamp) }.count)",
                            color: .blue
                        )

                        VoiceStatCard(
                            icon: "checkmark.circle.fill",
                            title: "Success Rate",
                            value: "\(successRate)%",
                            color: .green
                        )

                        VoiceStatCard(
                            icon: "sparkles",
                            title: "Shortcuts",
                            value: "\(voiceManager.suggestedShortcuts.count)",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 80)

                    // Most Used Commands
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Most Used Commands")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 20)], spacing: 20) {
                            ForEach(voiceManager.getMostUsedCommands(limit: 6), id: \.self) { command in
                                MostUsedCommandCard(command: command)
                            }
                        }
                        .padding(.horizontal, 80)
                    }

                    // Suggested Shortcuts
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Suggested Shortcuts")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        ForEach(voiceManager.suggestedShortcuts.prefix(5)) { shortcut in
                            ShortcutRow(shortcut: shortcut)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Command History
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Recent Commands")
                                .font(.title2)

                            Spacer()

                            Text("\(voiceManager.voiceHistory.count) total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 80)

                        ForEach(voiceManager.voiceHistory.prefix(10)) { command in
                            VoiceCommandRow(command: command)
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingShortcutBuilder) {
            ShortcutBuilderView(isPresented: $showingShortcutBuilder)
                .environmentObject(homeManager)
        }
    }

    private var successRate: Int {
        guard !voiceManager.voiceHistory.isEmpty else { return 0 }
        let successful = voiceManager.voiceHistory.filter { $0.success }.count
        return Int((Double(successful) / Double(voiceManager.voiceHistory.count)) * 100)
    }
}

/// Voice statistic card
struct VoiceStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 40, weight: .bold))

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

/// Most used command card
struct MostUsedCommandCard: View {
    let command: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "waveform")
                .font(.system(size: 30))
                .foregroundColor(.blue)

            Text(command)
                .font(.body)
                .lineLimit(2)

            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Shortcut row display
struct ShortcutRow: View {
    let shortcut: VoiceShortcut

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "bubble.left.fill")
                .font(.system(size: 30))
                .foregroundColor(.purple)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text("\"\(shortcut.phrase)\"")
                    .font(.body)
                    .bold()

                Text(shortcut.action.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                // Add to Siri
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text("Add to Siri")
                }
                .font(.caption)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

/// Voice command history row
struct VoiceCommandRow: View {
    let command: VoiceCommand

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: command.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 25))
                .foregroundColor(command.success ? .green : .red)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                Text(command.command)
                    .font(.body)

                HStack(spacing: 15) {
                    Text(command.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let deviceName = command.deviceName {
                        Text(deviceName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

/// Shortcut builder sheet
struct ShortcutBuilderView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var voiceManager = VoiceControlManager.shared
    @Binding var isPresented: Bool

    @State private var selectedDevice: HMAccessory?
    @State private var selectedScene: HMActionSet?
    @State private var selectedAction: DeviceAction = .toggle
    @State private var customPhrase = ""
    @State private var shortcutType: ShortcutType = .device

    enum ShortcutType: String, CaseIterable {
        case device = "Device"
        case scene = "Scene"
        case custom = "Custom"
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Create Voice Shortcut")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            // Type Picker
            Picker("Type", selection: $shortcutType) {
                ForEach(ShortcutType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 80)

            ScrollView {
                VStack(spacing: 25) {
                    switch shortcutType {
                    case .device:
                        deviceShortcutBuilder
                    case .scene:
                        sceneShortcutBuilder
                    case .custom:
                        customShortcutBuilder
                    }
                }
            }

            HStack(spacing: 20) {
                Button("Cancel") {
                    isPresented = false
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)

                Button("Create") {
                    createShortcut()
                    isPresented = false
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
    }

    private var deviceShortcutBuilder: some View {
        VStack(spacing: 20) {
            Text("Select Device")
                .font(.title3)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 15)], spacing: 15) {
                ForEach(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
                    Button(action: {
                        selectedDevice = accessory
                        customPhrase = "Turn \(selectedAction.rawValue.lowercased()) \(accessory.name)"
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 30))
                            Text(accessory.name)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selectedDevice?.uniqueIdentifier == accessory.uniqueIdentifier ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(selectedDevice?.uniqueIdentifier == accessory.uniqueIdentifier ? .white : .primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 80)

            Picker("Action", selection: $selectedAction) {
                Text("Turn On").tag(DeviceAction.on)
                Text("Turn Off").tag(DeviceAction.off)
                Text("Toggle").tag(DeviceAction.toggle)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 80)

            TextField("Voice Phrase", text: $customPhrase)
                .font(.title3)
                .padding(20)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 80)
        }
    }

    private var sceneShortcutBuilder: some View {
        VStack(spacing: 20) {
            Text("Select Scene")
                .font(.title3)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 15)], spacing: 15) {
                ForEach(homeManager.scenes, id: \.uniqueIdentifier) { scene in
                    Button(action: {
                        selectedScene = scene
                        customPhrase = "Activate \(scene.name)"
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 30))
                            Text(scene.name)
                                .font(.caption)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(selectedScene?.uniqueIdentifier == scene.uniqueIdentifier ? Color.purple : Color.gray.opacity(0.2))
                        .foregroundColor(selectedScene?.uniqueIdentifier == scene.uniqueIdentifier ? .white : .primary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 80)

            TextField("Voice Phrase", text: $customPhrase)
                .font(.title3)
                .padding(20)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 80)
        }
    }

    private var customShortcutBuilder: some View {
        VStack(spacing: 20) {
            Text("Create Custom Command")
                .font(.title3)

            TextField("What do you want to say?", text: $customPhrase)
                .font(.title3)
                .padding(20)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal, 80)

            Text("Examples: \"Good morning\", \"I'm leaving\", \"Movie time\"")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func createShortcut() {
        switch shortcutType {
        case .device:
            if let device = selectedDevice {
                voiceManager.createShortcut(for: device, action: selectedAction, phrase: customPhrase)
            }
        case .scene:
            if let scene = selectedScene {
                voiceManager.createShortcut(for: scene, phrase: customPhrase)
            }
        case .custom:
            // Create custom shortcut
            let shortcut = VoiceShortcut(
                id: UUID(),
                phrase: customPhrase,
                action: .scene,
                createdAt: Date()
            )
            voiceManager.suggestedShortcuts.append(shortcut)
        }
    }
}

#Preview {
    VoiceControlView()
        .environmentObject(HomeKitManager())
}
