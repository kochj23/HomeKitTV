import SwiftUI
import MediaPlayer
import HomeKit

/// Apple TV Remote Control built into app
///
/// Features:
/// - Swipe pad for navigation
/// - Play/pause/skip controls
/// - Volume control
/// - Menu/Home buttons
/// - Siri button
struct AppleTVRemoteView: View {
    @State private var volume: Double = 50

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("Apple TV Remote")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 60)

                // Touchpad
                VStack(spacing: 30) {
                    TouchpadView()
                        .frame(width: 500, height: 500)

                    // Menu and Home
                    HStack(spacing: 60) {
                        RemoteButton(icon: "line.3.horizontal", label: "Menu", action: {
                            // Menu button
                        })

                        RemoteButton(icon: "tv.fill", label: "Home", action: {
                            // Home button
                        })
                    }
                }

                // Playback Controls
                HStack(spacing: 50) {
                    RemoteButton(icon: "backward.fill", label: "Rewind", action: {})
                    RemoteButton(icon: "playpause.fill", label: "Play/Pause", action: {})
                    RemoteButton(icon: "forward.fill", label: "Forward", action: {})
                }

                // Volume Control
                VStack(spacing: 20) {
                    Text("Volume: \(Int(volume))%")
                        .font(.title3)

                    HStack(spacing: 40) {
                        Button(action: {
                            volume = max(0, volume - 10)
                        }) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 40))
                        }
                        .buttonStyle(.plain)

                        Text("\(Int(volume))%")
                            .font(.title2)
                            .frame(minWidth: 100)

                        Button(action: {
                            volume = min(100, volume + 10)
                        }) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 40))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)

                Spacer()
            }
            .padding(.horizontal, 80)
        }
    }
}

/// Touchpad view for navigation
struct TouchpadView: View {
    @State private var touchLocation: CGPoint = .zero

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.gray.opacity(0.2))

            // Direction indicators
            VStack {
                Image(systemName: "arrow.up")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
            }
            .padding(.top, 40)

            HStack {
                Image(systemName: "arrow.left")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 40)

            VStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.bottom, 40)

            // Center button
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Text("SELECT")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.blue, lineWidth: 3)
        )
    }
}

/// Remote button
struct RemoteButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 35))
                Text(label)
                    .font(.body)
            }
            .frame(width: 120, height: 120)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Now Playing View

/// Now Playing integration view
struct NowPlayingView: View {
    @StateObject private var nowPlayingManager = NowPlayingManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Now Playing")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    if let media = nowPlayingManager.currentMedia {
                        VStack(spacing: 30) {
                            // Artwork
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 400, height: 400)
                                .cornerRadius(20)
                                .overlay(
                                    Image(systemName: "play.rectangle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white)
                                )

                            // Media Info
                            VStack(spacing: 12) {
                                Text(media.title)
                                    .font(.largeTitle)
                                    .bold()

                                Text(media.artist)
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                Text(media.album)
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }

                            // Controls
                            HStack(spacing: 50) {
                                Button(action: nowPlayingManager.previousTrack) {
                                    Image(systemName: "backward.fill")
                                        .font(.system(size: 50))
                                }
                                .buttonStyle(.plain)

                                Button(action: nowPlayingManager.playPause) {
                                    Image(systemName: nowPlayingManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                        .font(.system(size: 70))
                                }
                                .buttonStyle(.plain)

                                Button(action: nowPlayingManager.nextTrack) {
                                    Image(systemName: "forward.fill")
                                        .font(.system(size: 50))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 80)
                    } else {
                        VStack(spacing: 30) {
                            Image(systemName: "play.tv")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("Nothing Playing")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}


// MARK: - Managers

/// Now Playing manager
class NowPlayingManager: ObservableObject {
    static let shared = NowPlayingManager()

    @Published var currentMedia: MediaInfo?
    @Published var isPlaying: Bool = false

    func playPause() {
        isPlaying.toggle()
    }

    func nextTrack() {
        // Skip to next
    }

    func previousTrack() {
        // Go to previous
    }
}

/// Media info model
struct MediaInfo {
    let title: String
    let artist: String
    let album: String
    let artwork: String?
}

/// Gaming mode manager
class GamingModeManager: ObservableObject {
    static let shared = GamingModeManager()

    @Published var isActive: Bool = false
    @Published var settings: GamingModeSettings

    init() {
        self.settings = GamingModeSettings()
    }

    func activateGamingMode(homeManager: HomeKitManager) {
        isActive = true

        if settings.dimLights {
            dimAllLights(homeManager: homeManager)
        }

        if settings.closeBlinds {
            closeAllBlinds(homeManager: homeManager)
        }

        if settings.reduceFanNoise {
            reduceAllFans(homeManager: homeManager)
        }
    }

    func deactivateGamingMode(homeManager: HomeKitManager) {
        isActive = false
        // Restore previous states
    }

    private func dimAllLights(homeManager: HomeKitManager) {
        let lights = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLightbulb } }

        for light in lights {
            if let service = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }),
               let brightnessChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
                homeManager.setBrightness(brightnessChar, value: 20)
            }
        }
    }

    private func closeAllBlinds(homeManager: HomeKitManager) {
        let blinds = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeWindowCovering } }

        for blind in blinds {
            if let service = blind.services.first(where: { $0.serviceType == HMServiceTypeWindowCovering }),
               let positionChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetPosition }) {
                homeManager.setWindowCoveringPosition(positionChar, position: 0) { _ in }
            }
        }
    }

    private func reduceAllFans(homeManager: HomeKitManager) {
        let fans = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeFan } }

        for fan in fans {
            if let service = fan.services.first(where: { $0.serviceType == HMServiceTypeFan }),
               let speedChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeRotationSpeed }) {
                homeManager.setFanSpeed(speedChar, speed: 25) { _ in }
            }
        }
    }
}

struct GamingModeSettings {
    var dimLights: Bool = true
    var closeBlinds: Bool = true
    var reduceFanNoise: Bool = true
    var muteNotifications: Bool = true
}

#Preview {
    AppleTVRemoteView()
}
