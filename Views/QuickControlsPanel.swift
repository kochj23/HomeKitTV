import SwiftUI
import HomeKit

/// Floating quick controls panel for favorite accessories and scenes
struct QuickControlsPanel: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @Binding var isPresented: Bool

    var favoriteAccessories: [HMAccessory] {
        homeManager.favoriteAccessories()
    }

    var favoriteScenes: [HMActionSet] {
        homeManager.favoriteScenes()
    }

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Panel content
            VStack(spacing: 30) {
                HStack {
                    Text("Quick Controls")
                        .font(.largeTitle)
                        .bold()

                    Spacer()

                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)

                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        // Favorite Accessories
                        if !favoriteAccessories.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Favorite Accessories")
                                    .font(.title2)
                                    .padding(.horizontal, 60)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 25)], spacing: 25) {
                                    ForEach(favoriteAccessories, id: \.uniqueIdentifier) { accessory in
                                        QuickAccessoryCard(accessory: accessory)
                                    }
                                }
                                .padding(.horizontal, 60)
                            }
                        }

                        // Favorite Scenes
                        if !favoriteScenes.isEmpty {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Favorite Scenes")
                                    .font(.title2)
                                    .padding(.horizontal, 60)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 250), spacing: 25)], spacing: 25) {
                                    ForEach(favoriteScenes, id: \.uniqueIdentifier) { scene in
                                        QuickSceneCard(scene: scene)
                                    }
                                }
                                .padding(.horizontal, 60)
                            }
                        }

                        // Empty State
                        if favoriteAccessories.isEmpty && favoriteScenes.isEmpty {
                            VStack(spacing: 25) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.secondary)
                                Text("No Favorites")
                                    .font(.title2)
                                Text("Long press accessories or scenes to mark them as favorites")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(80)
                        }
                    }
                }
            }
            .frame(width: 1400, height: 900)
            .background(.ultraThinMaterial)
            .cornerRadius(30)
        }
    }
}

/// Compact quick control accessory card
struct QuickAccessoryCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessory: HMAccessory

    var isOn: Bool {
        homeManager.getPowerState(accessory)
    }

    var body: some View {
        Button(action: {
            homeManager.toggleAccessory(accessory)
        }) {
            HStack(spacing: 15) {
                Image(systemName: iconForAccessory(accessory))
                    .font(.system(size: 35))
                    .foregroundColor(isOn ? .blue : .secondary)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(accessory.name)
                        .font(.title3)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(accessory.room?.name ?? "No Room")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isOn ? "power.circle.fill" : "power.circle")
                    .font(.system(size: 30))
                    .foregroundColor(isOn ? .green : .secondary)
            }
            .padding(20)
            .background(isOn ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }

    func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let primaryService = accessory.services.first else {
            return "lightbulb.fill"
        }

        switch primaryService.serviceType {
        case HMServiceTypeLightbulb:
            return "lightbulb.fill"
        case HMServiceTypeOutlet:
            return "poweroutlet.type.b.fill"
        case HMServiceTypeSwitch:
            return "light.switch.on.fill"
        case HMServiceTypeThermostat:
            return "thermometer"
        case HMServiceTypeFan:
            return "fan.fill"
        default:
            return "circle.fill"
        }
    }
}

/// Compact quick control scene card
struct QuickSceneCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet

    var body: some View {
        Button(action: {
            homeManager.executeScene(scene)
        }) {
            HStack(spacing: 15) {
                Image(systemName: "sparkles")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)

                Text(scene.name)
                    .font(.title3)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.green)
            }
            .padding(20)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickControlsPanel(isPresented: .constant(true))
        .environmentObject(HomeKitManager())
}
