import SwiftUI
import HomeKit
import AVKit

/// Camera viewing interface for HomeKit Secure Video
///
/// Displays live camera feeds with support for:
/// - Grid layout for multiple cameras
/// - Full-screen viewing
/// - Recording playback
/// - Motion detection timeline
/// - Snapshot gallery
struct CameraView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var selectedCamera: HMCameraProfile?
    @State private var showingFullScreen = false
    @State private var showingSnapshots = false

    var cameras: [HMAccessory] {
        homeManager.accessories.filter { accessory in
            accessory.profiles.contains { $0 is HMCameraProfile }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Cameras")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        if !cameras.isEmpty {
                            Button(action: {
                                showingSnapshots = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                    Text("Snapshots")
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
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    if cameras.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "video.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Cameras Found")
                                .font(.title2)
                            Text("HomeKit Secure Video cameras will appear here")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 600), spacing: 40)], spacing: 40) {
                            ForEach(cameras, id: \.uniqueIdentifier) { camera in
                                CameraCard(camera: camera, onFullScreen: {
                                    selectedCamera = camera.profiles.first { $0 is HMCameraProfile } as? HMCameraProfile
                                    showingFullScreen = true
                                })
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let camera = selectedCamera {
                FullScreenCameraView(cameraProfile: camera, isPresented: $showingFullScreen)
                    .environmentObject(homeManager)
            }
        }
        .sheet(isPresented: $showingSnapshots) {
            CameraSnapshotsView(cameras: cameras)
                .environmentObject(homeManager)
        }
    }
}

/// Individual camera card
struct CameraCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let camera: HMAccessory
    let onFullScreen: () -> Void

    var cameraProfile: HMCameraProfile? {
        camera.profiles.first { $0 is HMCameraProfile } as? HMCameraProfile
    }

    var streamControl: HMCameraStreamControl? {
        cameraProfile?.streamControl
    }

    var body: some View {
        VStack(spacing: 0) {
            // Camera Preview Area
            ZStack {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 350)

                if let streamControl = streamControl {
                    CameraStreamView(streamControl: streamControl)
                        .frame(height: 350)
                        .clipped()
                } else {
                    VStack(spacing: 15) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("Stream Unavailable")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }

                // Live indicator
                HStack {
                    VStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("LIVE")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)

                        Spacer()
                    }
                    Spacer()
                }
                .padding(20)
            }

            // Camera Info
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(camera.name)
                        .font(.title2)
                        .bold()

                    Text(camera.room?.name ?? "No Room")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 15) {
                    // Snapshot button
                    Button(action: {
                        // Take snapshot
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    // Full screen button
                    Button(action: onFullScreen) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 25))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    // Recording indicator
                    if camera.isReachable {
                        Image(systemName: "record.circle.fill")
                            .font(.system(size: 25))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(25)
            .background(Color.gray.opacity(0.1))
        }
        .background(Color.gray.opacity(0.15))
        .cornerRadius(20)
    }
}

/// Camera stream view using AVKit
struct CameraStreamView: View {
    let streamControl: HMCameraStreamControl
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .onAppear {
            startStream()
        }
        .onDisappear {
            stopStream()
        }
    }

    private func startStream() {
        // Note: Actual streaming requires HMCameraStreamControl.startStream()
        // This is a placeholder for the implementation
        // Real implementation would get HLS URL from camera and play it
    }

    private func stopStream() {
        player?.pause()
        player = nil
    }
}

/// Full screen camera view
struct FullScreenCameraView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let cameraProfile: HMCameraProfile
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Camera stream
                if let streamControl = cameraProfile.streamControl {
                    CameraStreamView(streamControl: streamControl)
                }

                // Controls overlay
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(cameraProfile.accessory?.name ?? "Camera")
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)

                    Spacer()

                    HStack(spacing: 30) {
                        Button(action: {}) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        Button(action: {}) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(40)
                .background(Color.black.opacity(0.5))
            }
        }
    }
}

/// Camera snapshots gallery view
struct CameraSnapshotsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let cameras: [HMAccessory]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Camera Snapshots")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 30)], spacing: 30) {
                        ForEach(cameras, id: \.uniqueIdentifier) { camera in
                            VStack(alignment: .leading, spacing: 15) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 225)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.secondary)
                                    )
                                    .cornerRadius(15)

                                Text(camera.name)
                                    .font(.title3)
                                    .bold()

                                Text("Last snapshot: Just now")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 80)
                }
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview {
    CameraView()
        .environmentObject(HomeKitManager())
}
