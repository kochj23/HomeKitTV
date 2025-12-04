import SwiftUI
import HomeKit

struct CameraGridView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var cameraManager = CameraManager.shared
    
    let columns = [
        GridItem(.adaptive(minimum: 500), spacing: 20)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text("Cameras")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 80)
                    .padding(.top, 60)
                
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(cameraManager.cameras, id: \.uniqueIdentifier) { camera in
                        CameraFeedCard(camera: camera)
                    }
                }
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 60)
        }
        .onAppear {
            cameraManager.loadCameras(homeManager.accessories)
        }
    }
}

struct CameraFeedCard: View {
    let camera: HMCameraProfile
    @State private var snapshot: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 300)
                .overlay(
                    Group {
                        if let data = snapshot, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            VStack {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("Loading...")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(camera.accessory?.name ?? "Camera")
                        .font(.body)
                        .bold()
                    
                    Text("Live")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            .padding(15)
            .background(Color.gray.opacity(0.1))
        }
        .cornerRadius(15)
    }
}