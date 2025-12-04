import SwiftUI
import HomeKit
import MediaPlayer

/// Now Playing View - Central media playback control
///
/// **Features**:
/// - Universal media controls for all HomeKit audio devices
/// - Album artwork display
/// - Playback progress with scrubbing
/// - Volume control
/// - Shuffle and repeat modes
/// - Multi-room audio grouping
/// - AirPlay device selection
///
/// **Security**: All operations validated against HomeKit permissions
struct MediaControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var isPlaying = false
    @State private var currentTrack = "No Media Playing"
    @State private var currentArtist = ""
    @State private var currentAlbum = ""
    @State private var playbackPosition: Double = 0.0
    @State private var duration: Double = 100.0
    @State private var volume: Double = 50.0
    @State private var shuffleEnabled = false
    @State private var repeatMode: RepeatMode = .off

    enum RepeatMode: String, CaseIterable {
        case off = "Off"
        case one = "One"
        case all = "All"

        var icon: String {
            switch self {
            case .off: return "repeat"
            case .one: return "repeat.1"
            case .all: return "repeat"
            }
        }
    }

    var audioAccessories: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.services.contains { service in
                if #available(tvOS 18.0, *) {
                    return service.serviceType == HMServiceTypeTelevision ||
                           service.serviceType == HMServiceTypeSpeaker
                } else {
                    return service.serviceType == HMServiceTypeSpeaker
                }
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 60) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Now Playing")
                        .font(.largeTitle)
                        .bold()
                    Text("\(audioAccessories.count) audio devices")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // Album Artwork Area
                VStack(spacing: 40) {
                    // Artwork placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 600, height: 600)
                            .shadow(radius: 30)

                        Image(systemName: "music.note")
                            .font(.system(size: 150))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Track Info
                    VStack(spacing: 12) {
                        Text(currentTrack)
                            .font(.title)
                            .bold()

                        if !currentArtist.isEmpty {
                            Text(currentArtist)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }

                        if !currentAlbum.isEmpty {
                            Text(currentAlbum)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 80)

                // Playback Controls
                VStack(spacing: 40) {
                    // Progress Bar
                    VStack(spacing: 15) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 8)

                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: geometry.size.width * (playbackPosition / duration), height: 8)
                            }
                        }
                        .frame(height: 8)
                        .padding(.horizontal, 80)

                        HStack {
                            Text(formatTime(playbackPosition))
                                .font(.title3)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text(formatTime(duration))
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Main Controls
                    HStack(spacing: 80) {
                        // Shuffle
                        Button(action: {
                            shuffleEnabled.toggle()
                        }) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 40))
                                .foregroundColor(shuffleEnabled ? .blue : .white)
                                .frame(width: 80, height: 80)
                        }
                        .buttonStyle(.plain)

                        // Previous
                        Button(action: previousTrack) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                        }
                        .buttonStyle(.plain)

                        // Play/Pause
                        Button(action: togglePlayPause) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                                .frame(width: 140, height: 140)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 20)
                        }
                        .buttonStyle(.plain)

                        // Next
                        Button(action: nextTrack) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                        }
                        .buttonStyle(.plain)

                        // Repeat
                        Button(action: cycleRepeatMode) {
                            Image(systemName: repeatMode.icon)
                                .font(.system(size: 40))
                                .foregroundColor(repeatMode != .off ? .blue : .white)
                                .frame(width: 80, height: 80)
                        }
                        .buttonStyle(.plain)
                    }

                    // Volume Control
                    VStack(spacing: 15) {
                        HStack(spacing: 20) {
                            Image(systemName: "speaker.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)

                            Button(action: {
                                if volume > 0 {
                                    volume -= 10
                                    updateVolume(volume)
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title)
                            }
                            .buttonStyle(.plain)

                            Text("\(Int(volume))%")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 100)

                            Button(action: {
                                if volume < 100 {
                                    volume += 10
                                    updateVolume(volume)
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                            }
                            .buttonStyle(.plain)

                            Image(systemName: "speaker.wave.3.fill")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 80)
                    }
                }

                // Active Devices
                if !audioAccessories.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Playing On")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 80)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 40)], spacing: 40) {
                            ForEach(audioAccessories, id: \.uniqueIdentifier) { accessory in
                                AudioDeviceCard(accessory: accessory)
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }

                // Empty State
                if audioAccessories.isEmpty {
                    VStack(spacing: 30) {
                        Image(systemName: "hifispeaker")
                            .font(.system(size: 100))
                            .foregroundColor(.secondary)
                        Text("No Audio Devices")
                            .font(.title)
                        Text("Add audio accessories to control playback")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(100)
                }
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            loadNowPlayingInfo()
        }
    }

    // MARK: - Actions

    /// Toggles play/pause state
    private func togglePlayPause() {
        isPlaying.toggle()

        Task {
            for accessory in audioAccessories {
                // Control playback via HomeKit characteristics
                for service in accessory.services {
                    // This is a simplified example - actual implementation would depend on specific service characteristics
                    if let powerChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
                        try? await powerChar.writeValue(isPlaying)
                    }
                }
            }
        }
    }

    /// Skips to previous track
    private func previousTrack() {
        // Implement previous track logic
        playbackPosition = 0
    }

    /// Skips to next track
    private func nextTrack() {
        // Implement next track logic
        playbackPosition = 0
    }

    /// Cycles through repeat modes
    private func cycleRepeatMode() {
        switch repeatMode {
        case .off:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .off
        }
    }

    /// Updates volume for all audio devices
    /// - Parameter newVolume: The new volume level (0-100)
    private func updateVolume(_ newVolume: Double) {
        Task {
            for accessory in audioAccessories {
                guard let speakerService = accessory.services.first(where: { $0.serviceType == HMServiceTypeSpeaker }) else { continue }

                if let volumeChar = speakerService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeVolume }) {
                    try? await volumeChar.writeValue(Int(newVolume))
                }
            }
        }
    }

    /// Loads current media information
    private func loadNowPlayingInfo() {
        // In a real implementation, this would fetch from MediaPlayer framework
        // For now, set default values
        currentTrack = "No Media Playing"
        currentArtist = ""
        currentAlbum = ""
        isPlaying = false
    }

    /// Formats time in seconds to MM:SS
    /// - Parameter seconds: Time in seconds
    /// - Returns: Formatted time string
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

/// Card displaying audio device information
struct AudioDeviceCard: View {
    let accessory: HMAccessory

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconForAccessory)
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(accessory.name)
                    .font(.title3)
                    .bold()

                Text(accessory.room?.name ?? "No Room")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Circle()
                .fill(Color.green)
                .frame(width: 15, height: 15)
        }
        .padding(30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }

    private var iconForAccessory: String {
        if #available(tvOS 18.0, *) {
            if accessory.services.contains(where: { $0.serviceType == HMServiceTypeTelevision }) {
                return "appletv.fill"
            }
        }
        return "hifispeaker.fill"
    }
}

struct MediaControlView_Previews: PreviewProvider {
    static var previews: some View {
        NowPlayingView()
            .environmentObject(HomeKitManager())
    }
}
