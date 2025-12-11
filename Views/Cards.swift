import SwiftUI
import HomeKit

// MARK: - Helper Functions

/// Determine icon for a HomeKit accessory based on its service types
func iconForAccessory(_ accessory: HMAccessory) -> String {
    // Check primary service types
    for service in accessory.services {
        switch service.serviceType {
        case HMServiceTypeLightbulb:
            return "lightbulb.fill"
        case HMServiceTypeOutlet:
            return "powerplug.fill"
        case HMServiceTypeSwitch:
            return "switch.2"
        case HMServiceTypeThermostat:
            return "thermometer"
        case HMServiceTypeFan:
            return "fan.fill"
        case HMServiceTypeGarageDoorOpener:
            return "garage.closed"
        case HMServiceTypeLockMechanism:
            return "lock.fill"
        case HMServiceTypeSecuritySystem:
            return "shield.fill"
        case HMServiceTypeMotionSensor:
            return "figure.walk.motion"
        case HMServiceTypeContactSensor:
            return "sensor.fill"
        case HMServiceTypeSmokeSensor:
            return "smoke.fill"
        case HMServiceTypeTemperatureSensor:
            return "thermometer"
        case HMServiceTypeCameraRTPStreamManagement:
            return "video.fill"
        case HMServiceTypeDoorbell:
            return "bell.fill"
        case HMServiceTypeWindow:
            return "rectangle.portrait.on.rectangle.portrait"
        case HMServiceTypeWindowCovering:
            return "blinds.vertical.closed"
        case HMServiceTypeValve:
            return "drop.fill"
        default:
            continue
        }
    }
    return "app.fill"
}

/// Determine icon for a HomeKit scene based on its name
func iconForScene(_ scene: HMActionSet) -> String {
    let name = scene.name.lowercased()
    if name.contains("sleep") || name.contains("night") || name.contains("bedtime") {
        return "moon.stars.fill"
    } else if name.contains("wake") || name.contains("morning") || name.contains("sunrise") {
        return "sunrise.fill"
    } else if name.contains("work") || name.contains("focus") {
        return "desktopcomputer"
    } else if name.contains("relax") || name.contains("chill") {
        return "sofa.fill"
    } else if name.contains("party") || name.contains("entertain") {
        return "party.popper.fill"
    } else if name.contains("arrive") || name.contains("home") {
        return "house.fill"
    } else if name.contains("leave") || name.contains("away") {
        return "figure.walk"
    } else if name.contains("movie") || name.contains("watch") {
        return "tv.fill"
    } else if name.contains("read") {
        return "book.fill"
    } else if name.contains("dinner") || name.contains("meal") {
        return "fork.knife"
    } else {
        return "sparkles"
    }
}

// MARK: - Card Components

/// Reusable card component for displaying an accessory
///
/// This card shows:
/// - Accessory icon (dynamically determined by service type)
/// - Power state indicator
/// - Accessory name
/// - Room assignment
/// - Visual feedback for on/off state
///
/// **Interaction**: Tapping toggles the accessory power state
///
/// **Visual Design**:
/// - 400x250pt fixed size
/// - Blue tint when on, gray when off
/// - Rounded corners
///
/// - Note: Only shows power control if accessory has power state characteristic
struct AccessoryCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessory: HMAccessory

    var primaryService: HMService? {
        accessory.services.first(where: {
            $0.characteristics.contains(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        })
    }

    var isOn: Bool {
        homeManager.getPowerState(accessory)
    }

    var batteryLevel: Int? {
        homeManager.getBatteryLevel(accessory)
    }

    var isLowBattery: Bool {
        homeManager.isLowBattery(accessory)
    }

    var body: some View {
        Button(action: {
            if primaryService != nil {
                homeManager.toggleAccessory(accessory)
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: iconForAccessory(accessory))
                        .font(.system(size: 50))
                        .foregroundColor(isOn ? .blue : .secondary)

                    Spacer()

                    HStack(spacing: 12) {
                        // Battery indicator
                        if let battery = batteryLevel, Settings.shared.showBatteryLevels {
                            HStack(spacing: 4) {
                                Image(systemName: batteryIcon(for: battery))
                                    .font(.system(size: 20))
                                    .foregroundColor(isLowBattery ? .red : .secondary)
                                Text("\(battery)%")
                                    .font(.caption)
                                    .foregroundColor(isLowBattery ? .red : .secondary)
                            }
                        }

                        // Reachability indicator
                        if Settings.shared.showReachabilityIndicators {
                            Image(systemName: accessory.isReachable ? "wifi" : "wifi.slash")
                                .font(.system(size: 20))
                                .foregroundColor(accessory.isReachable ? .green : .red)
                        }

                        // Power indicator
                        if primaryService != nil {
                            Image(systemName: isOn ? "power.circle.fill" : "power.circle")
                                .font(.system(size: 40))
                                .foregroundColor(isOn ? .green : .secondary)
                        }
                    }
                }

                Text(accessory.name)
                    .font(.headline)  // Dynamic Type support
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(accessory.room?.name ?? "No Room")
                    .font(.caption)  // Dynamic Type support
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.7)
            }
            .padding(20)
            .frame(width: 350, height: 200)
            .background(isOn ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
            .cornerRadius(16)
            .opacity(accessory.isReachable ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(primaryService != nil ? .isButton : [])
        .accessibilityRemoveTraits(accessory.isReachable ? [] : .isButton)
    }

    /// Accessibility label for VoiceOver
    private var accessibilityLabel: String {
        "\(accessory.name) in \(accessory.room?.name ?? "No Room")"
    }

    /// Accessibility hint for VoiceOver
    private var accessibilityHint: String {
        if !accessory.isReachable {
            return "Not responding"
        }
        return primaryService != nil ? "Double tap to toggle power" : "View accessory details"
    }

    /// Accessibility value for VoiceOver
    private var accessibilityValue: String {
        var components: [String] = []

        if let service = primaryService {
            components.append(isOn ? "On" : "Off")
        }

        if let battery = batteryLevel {
            let batteryStatus = isLowBattery ? "Low battery" : "Battery"
            components.append("\(batteryStatus) \(battery) percent")
        }

        if !accessory.isReachable {
            components.append("Not reachable")
        }

        return components.isEmpty ? "No status" : components.joined(separator: ", ")
    }

    /// Get appropriate battery icon based on level
    func batteryIcon(for level: Int) -> String {
        if isLowBattery {
            return "battery.0"
        } else if level > 75 {
            return "battery.100"
        } else if level > 50 {
            return "battery.75"
        } else if level > 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    /// Determines the appropriate SF Symbol icon for an accessory
    ///
    /// Maps HomeKit service types to SF Symbol names for visual representation.
    ///
    /// - Parameter accessory: The accessory to get an icon for
    /// - Returns: SF Symbol name as string
    ///
    /// **Supported Types**:
    /// - Lightbulb, Outlet, Switch, Thermostat, Fan, Garage Door, Lock,
    ///   Security System, Door, Window
    /// - Default: "circle.fill" for unknown types
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
        case HMServiceTypeGarageDoorOpener:
            return "garage.closed"
        case HMServiceTypeLockMechanism:
            return "lock.fill"
        case HMServiceTypeSecuritySystem:
            return "shield.fill"
        case HMServiceTypeDoor:
            return "door.left.hand.closed"
        case HMServiceTypeWindow:
            return "window.vertical.closed"
        default:
            return "circle.fill"
        }
    }
}

/// Reusable card component for displaying a room
///
/// This card shows:
/// - Room icon (inferred from room name)
/// - Room name
/// - Accessory count
/// - Active accessory count (if any are on)
///
/// **Visual Design**:
/// - 400x250pt fixed size
/// - Gray background
/// - Rounded corners
///
/// **Smart Features**:
/// - Shows "X on" badge when accessories are powered on
/// - Icon inference based on room name keywords
struct RoomCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let room: HMRoom

    var accessories: [HMAccessory] {
        homeManager.accessories(for: room)
    }

    var activeCount: Int {
        accessories.filter { homeManager.getPowerState($0) }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: iconForRoom(room))
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Spacer()

                if activeCount > 0 {
                    Text("\(activeCount) on")
                        .font(.title3)
                        .foregroundColor(.green)
                }
            }

            Text(room.name)
                .font(.headline)  // Dynamic Type support
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("\(accessories.count) accessories")
                .font(.caption)  // Dynamic Type support
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.7)
        }
        .padding(20)
        .frame(width: 350, height: 200)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(16)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(room.name) room")
        .accessibilityValue("\(accessories.count) accessories\(activeCount > 0 ? ", \(activeCount) turned on" : "")")
        .accessibilityHint("Double tap to view accessories in this room")
        .accessibilityAddTraits(.isButton)
    }

    /// Determines the appropriate SF Symbol icon for a room
    ///
    /// Uses keyword matching on room name to select contextually appropriate icons.
    ///
    /// - Parameter room: The room to get an icon for
    /// - Returns: SF Symbol name as string
    ///
    /// **Recognized Keywords**:
    /// - bedroom/bed → bed.double.fill
    /// - bathroom/bath → shower.fill
    /// - kitchen → refrigerator.fill
    /// - living → sofa.fill
    /// - dining → fork.knife
    /// - garage → garage.closed
    /// - office → desktopcomputer
    /// - Default: house.fill
    func iconForRoom(_ room: HMRoom) -> String {
        let name = room.name.lowercased()
        if name.contains("bedroom") || name.contains("bed") {
            return "bed.double.fill"
        } else if name.contains("bathroom") || name.contains("bath") {
            return "shower.fill"
        } else if name.contains("kitchen") {
            return "refrigerator.fill"
        } else if name.contains("living") {
            return "sofa.fill"
        } else if name.contains("dining") {
            return "fork.knife"
        } else if name.contains("garage") {
            return "garage.closed"
        } else if name.contains("office") {
            return "desktopcomputer"
        } else {
            return "house.fill"
        }
    }
}

/// Reusable card component for displaying a scene
///
/// This card shows:
/// - Scene icon (inferred from scene name)
/// - Scene name
/// - Favorite indicator
///
/// **Interaction**: Tapping executes the scene
///
/// **Visual Design**:
/// - 300x250pt fixed size
/// - Orange accent color
/// - Rounded corners
///
/// **Smart Features**:
/// - Icon inference based on scene name keywords
/// - Multiline text support for long scene names
/// - Favorite status with star icon
struct SceneCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet

    var isFavorite: Bool {
        Settings.shared.isFavorite(scene)
    }

    var body: some View {
        Button(action: {
            homeManager.executeScene(scene)
        }) {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                        .onTapGesture {
                            Settings.shared.toggleFavorite(scene)
                        }
                }
                .frame(height: 20)

                Image(systemName: iconForScene(scene))
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                Text(scene.name)
                    .font(.headline)  // Dynamic Type support
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .frame(width: 280, height: 200)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        // MARK: - Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Scene: \(scene.name)")
        .accessibilityHint("Double tap to execute this scene")
        .accessibilityValue("\(scene.actions.count) actions\(isFavorite ? ", favorited" : "")")
        .accessibilityAddTraits(.isButton)
    }

    /// Determines the appropriate SF Symbol icon for a scene
    ///
    /// Uses keyword matching on scene name to select contextually appropriate icons.
    ///
    /// - Parameter scene: The scene to get an icon for
    /// - Returns: SF Symbol name as string
    ///
    /// **Recognized Keywords**:
    /// - morning/wake → sunrise.fill
    /// - night/sleep/bedtime → moon.stars.fill
    /// - arrive/home → house.fill
    /// - leave/away → figure.walk
    /// - movie/watch → tv.fill
    /// - read → book.fill
    /// - dinner/meal → fork.knife
    /// - Default: sparkles
    func iconForScene(_ scene: HMActionSet) -> String {
        let name = scene.name.lowercased()
        if name.contains("morning") || name.contains("wake") {
            return "sunrise.fill"
        } else if name.contains("night") || name.contains("sleep") || name.contains("bedtime") {
            return "moon.stars.fill"
        } else if name.contains("arrive") || name.contains("home") {
            return "house.fill"
        } else if name.contains("leave") || name.contains("away") {
            return "figure.walk"
        } else if name.contains("movie") || name.contains("watch") {
            return "tv.fill"
        } else if name.contains("read") {
            return "book.fill"
        } else if name.contains("dinner") || name.contains("meal") {
            return "fork.knife"
        } else {
            return "sparkles"
        }
    }
}

// MARK: - Dynamic Sized Cards

/// Dynamic-sized Room Card that scales based on available space
struct DynamicRoomCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let room: HMRoom
    let size: CGSize

    var accessories: [HMAccessory] {
        homeManager.accessories(for: room)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: size.height * 0.06) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: size.width * 0.12))
                    .foregroundColor(.blue)

                Spacer()

                Text("\(accessories.count)")
                    .font(.system(size: size.width * 0.1, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Text(room.name)
                .font(.system(size: size.width * 0.08, weight: .bold))
                .lineLimit(2)
                .minimumScaleFactor(0.7)

            Text("\(accessories.count) accessories")
                .font(.system(size: size.width * 0.06))
                .foregroundColor(.secondary)
        }
        .padding(size.width * 0.06)
        .frame(width: size.width, height: size.height)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(size.width * 0.04)
    }
}

/// Dynamic-sized Scene Card that scales based on available space
struct DynamicSceneCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet
    let size: CGSize

    var body: some View {
        Button(action: {
            homeManager.executeScene(scene)
        }) {
            VStack(alignment: .leading, spacing: size.height * 0.06) {
                HStack {
                    Image(systemName: iconForScene(scene))
                        .font(.system(size: size.width * 0.12))
                        .foregroundColor(.orange)

                    Spacer()

                    Text("\(scene.actions.count)")
                        .font(.system(size: size.width * 0.1, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                Text(scene.name)
                    .font(.system(size: size.width * 0.08, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                Text("\(scene.actions.count) actions")
                    .font(.system(size: size.width * 0.06))
                    .foregroundColor(.secondary)
            }
            .padding(size.width * 0.06)
            .frame(width: size.width, height: size.height)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(size.width * 0.04)
        }
        .buttonStyle(.plain)
    }
}

/// Dynamic-sized Accessory Card that scales based on available space
struct DynamicAccessoryCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessory: HMAccessory
    let size: CGSize

    var primaryService: HMService? {
        accessory.services.first(where: {
            $0.characteristics.contains(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        })
    }

    var isOn: Bool {
        homeManager.getPowerState(accessory)
    }

    var body: some View {
        Button(action: {
            if primaryService != nil {
                homeManager.toggleAccessory(accessory)
            }
        }) {
            VStack(alignment: .leading, spacing: size.height * 0.05) {
                HStack {
                    Image(systemName: iconForAccessory(accessory))
                        .font(.system(size: size.width * 0.11))
                        .foregroundColor(isOn ? .blue : .secondary)

                    Spacer()

                    if primaryService != nil {
                        Image(systemName: isOn ? "power.circle.fill" : "power.circle")
                            .font(.system(size: size.width * 0.1))
                            .foregroundColor(isOn ? .green : .secondary)
                    }

                    if Settings.shared.showReachabilityIndicators {
                        Image(systemName: accessory.isReachable ? "wifi" : "wifi.slash")
                            .font(.system(size: size.width * 0.08))
                            .foregroundColor(accessory.isReachable ? .green : .red)
                    }
                }

                Text(accessory.name)
                    .font(.system(size: size.width * 0.07, weight: .bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                if let room = accessory.room {
                    Text(room.name)
                        .font(.system(size: size.width * 0.055))
                        .foregroundColor(.secondary)
                }
            }
            .padding(size.width * 0.05)
            .frame(width: size.width, height: size.height)
            .background(isOn ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(size.width * 0.04)
        }
        .buttonStyle(.plain)
    }
}
