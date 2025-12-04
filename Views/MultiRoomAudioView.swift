import SwiftUI
import HomeKit
import MediaPlayer

/// Multi-room audio control view for HomePod speakers
struct MultiRoomAudioView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @StateObject private var audioManager = AudioManager.shared

    var speakers: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeSpeaker }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Multi-Room Audio")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Master Controls
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Master Controls")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 25) {
                            // Global Volume
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "speaker.wave.3.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                    Text("Global Volume: \(Int(audioManager.globalVolume))%")
                                        .font(.title3)
                                }

                                HStack(spacing: 30) {
                                    Button(action: {
                                        audioManager.adjustGlobalVolume(-10)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 50))
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(Int(audioManager.globalVolume))%")
                                        .font(.system(size: 40, weight: .bold))
                                        .frame(minWidth: 120)

                                    Button(action: {
                                        audioManager.adjustGlobalVolume(10)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 50))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(30)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(20)

                            // Quick Actions
                            HStack(spacing: 20) {
                                Button(action: {
                                    audioManager.playPauseAll()
                                }) {
                                    HStack {
                                        Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        Text(audioManager.isPlaying ? "Pause All" : "Play All")
                                    }
                                    .font(.title3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    audioManager.muteAll()
                                }) {
                                    HStack {
                                        Image(systemName: audioManager.isMuted ? "speaker.slash.fill" : "speaker.fill")
                                        Text(audioManager.isMuted ? "Unmute All" : "Mute All")
                                    }
                                    .font(.title3)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 30)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Speaker Groups
                    if !audioManager.speakerGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            HStack {
                                Text("Speaker Groups")
                                    .font(.title2)

                                Spacer()

                                Button(action: {
                                    audioManager.showingCreateGroup = true
                                }) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("New Group")
                                    }
                                    .font(.title3)
                                    .padding(.horizontal, 25)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 80)

                            ForEach(audioManager.speakerGroups) { group in
                                SpeakerGroupCard(group: group)
                            }
                            .padding(.horizontal, 80)
                        }
                    }

                    // Individual Speakers
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Individual Speakers")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        ForEach(speakers, id: \.uniqueIdentifier) { speaker in
                            SpeakerCard(speaker: speaker)
                                .padding(.horizontal, 80)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $audioManager.showingCreateGroup) {
            CreateSpeakerGroupView()
                .environmentObject(homeManager)
        }
    }
}

/// Individual speaker card with controls
struct SpeakerCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let speaker: HMAccessory

    @State private var volume: Double = 50
    @State private var isMuted: Bool = false

    var volumeCharacteristic: HMCharacteristic? {
        speaker.services.first { $0.serviceType == HMServiceTypeSpeaker }?
            .characteristics.first { $0.characteristicType == HMCharacteristicTypeVolume }
    }

    var muteCharacteristic: HMCharacteristic? {
        speaker.services.first { $0.serviceType == HMServiceTypeSpeaker }?
            .characteristics.first { $0.characteristicType == HMCharacteristicTypeMute }
    }

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: "homepod.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .frame(width: 70)

            VStack(alignment: .leading, spacing: 8) {
                Text(speaker.name)
                    .font(.title3)
                    .bold()

                Text(speaker.room?.name ?? "No Room")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Volume Control
            HStack(spacing: 20) {
                Button(action: {
                    volume = max(0, volume - 10)
                    if let char = volumeCharacteristic {
                        homeManager.setBrightness(char, value: Int(volume))
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 40))
                }
                .buttonStyle(.plain)

                Text("\(Int(volume))%")
                    .font(.title3)
                    .frame(minWidth: 80)

                Button(action: {
                    volume = min(100, volume + 10)
                    if let char = volumeCharacteristic {
                        homeManager.setBrightness(char, value: Int(volume))
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                }
                .buttonStyle(.plain)

                // Mute toggle
                Button(action: {
                    isMuted.toggle()
                    if let char = muteCharacteristic {
                        char.writeValue(isMuted) { _ in }
                    }
                }) {
                    Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isMuted ? .red : .blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .onAppear {
            if let char = volumeCharacteristic {
                char.readValue { _ in
                    if let value = char.value as? Int {
                        volume = Double(value)
                    }
                }
            }
            if let char = muteCharacteristic {
                char.readValue { _ in
                    if let value = char.value as? Bool {
                        isMuted = value
                    }
                }
            }
        }
    }
}

/// Speaker group card
struct SpeakerGroupCard: View {
    let group: SpeakerGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "hifispeaker.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)

                Text(group.name)
                    .font(.title2)
                    .bold()

                Spacer()

                Text("\(group.speakerIDs.count) speakers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(30)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Create speaker group view
struct CreateSpeakerGroupView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var selectedSpeakers: Set<String> = []

    var speakers: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeSpeaker }
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Create Speaker Group")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            TextField("Group Name", text: $groupName)
                .font(.title3)
                .textFieldStyle(.plain)
                .padding(20)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 80)

            Text("Select Speakers")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 80)

            ScrollView {
                VStack(spacing: 15) {
                    ForEach(speakers, id: \.uniqueIdentifier) { speaker in
                        Button(action: {
                            let id = speaker.uniqueIdentifier.uuidString
                            if selectedSpeakers.contains(id) {
                                selectedSpeakers.remove(id)
                            } else {
                                selectedSpeakers.insert(id)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedSpeakers.contains(speaker.uniqueIdentifier.uuidString) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 30))
                                    .foregroundColor(.blue)

                                Text(speaker.name)
                                    .font(.title3)

                                Spacer()

                                Text(speaker.room?.name ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(selectedSpeakers.contains(speaker.uniqueIdentifier.uuidString) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 80)
            }

            HStack(spacing: 30) {
                Button("Cancel") {
                    dismiss()
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)

                Button("Create") {
                    AudioManager.shared.createSpeakerGroup(name: groupName, speakerIDs: selectedSpeakers)
                    dismiss()
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(groupName.isEmpty || selectedSpeakers.count < 2 ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)
                .disabled(groupName.isEmpty || selectedSpeakers.count < 2)
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Audio Manager

/// Manager for multi-room audio playback and speaker groups
class AudioManager: ObservableObject {
    static let shared = AudioManager()

    @Published var speakerGroups: [SpeakerGroup] = []
    @Published var globalVolume: Double = 50
    @Published var isPlaying: Bool = false
    @Published var isMuted: Bool = false
    @Published var showingCreateGroup: Bool = false

    private let groupsKey = "com.homekittv.speakerGroups"

    private init() {
        loadGroups()
    }

    func createSpeakerGroup(name: String, speakerIDs: Set<String>) {
        let group = SpeakerGroup(name: name, speakerIDs: speakerIDs)
        speakerGroups.append(group)
        saveGroups()
    }

    func deleteGroup(_ group: SpeakerGroup) {
        speakerGroups.removeAll { $0.id == group.id }
        saveGroups()
    }

    func adjustGlobalVolume(_ delta: Double) {
        globalVolume = max(0, min(100, globalVolume + delta))
        // Apply to all speakers
    }

    func playPauseAll() {
        isPlaying.toggle()
        // Control all speakers
    }

    func muteAll() {
        isMuted.toggle()
        // Mute all speakers
    }

    private func loadGroups() {
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let groups = try? JSONDecoder().decode([SpeakerGroup].self, from: data) {
            speakerGroups = groups
        }
    }

    private func saveGroups() {
        if let data = try? JSONEncoder().encode(speakerGroups) {
            UserDefaults.standard.set(data, forKey: groupsKey)
        }
    }
}

// MARK: - Models

/// Speaker group model
struct SpeakerGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var speakerIDs: Set<String>
    var volume: Double

    init(name: String, speakerIDs: Set<String>, volume: Double = 50) {
        self.id = UUID()
        self.name = name
        self.speakerIDs = speakerIDs
        self.volume = volume
    }
}

#Preview {
    MultiRoomAudioView()
        .environmentObject(HomeKitManager())
}
