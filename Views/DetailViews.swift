import SwiftUI
import HomeKit

/// Detail view for a specific room
///
/// Displays all accessories within a room in a grid layout.
///
/// **Features**:
/// - Room name and accessory count header
/// - Grid of accessory cards
/// - Navigation to individual accessory details
/// - Empty state messaging
///
/// **Layout**: Adaptive grid with 400pt minimum column width
struct RoomDetailView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let room: HMRoom

    var accessories: [HMAccessory] {
        homeManager.accessories(for: room)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(room.name)
                            .font(.largeTitle)
                            .bold()
                        Text("\(accessories.count) accessories")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                if accessories.isEmpty {
                    VStack(spacing: 30) {
                        Image(systemName: "apps.iphone")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                        Text("No Accessories in This Room")
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(80)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 40)], spacing: 40) {
                        ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                            NavigationLink(destination: AccessoryDetailView(accessory: accessory)) {
                                AccessoryCard(accessory: accessory)
                            }
                            .buttonStyle(.card)
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
            .padding(.bottom, 60)
        }
    }
}

/// Detail view for a specific accessory
///
/// Displays comprehensive information about an accessory including:
/// - Accessory icon, name, and room
/// - All controllable services with interactive controls
/// - Device information (manufacturer, model, firmware, reachability)
///
/// **Features**:
/// - Service control cards for each controllable service
/// - Brightness controls for dimmable lights
/// - Device metadata display
/// - Empty state for non-controllable accessories
///
/// **Layout**: Vertical scroll with sections
struct AccessoryDetailView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessory: HMAccessory
    @State private var brightnessValue: Double = 50

    var controllableServices: [HMService] {
        accessory.services.filter { service in
            service.characteristics.contains(where: {
                $0.characteristicType == HMCharacteristicTypePowerState ||
                $0.characteristicType == HMCharacteristicTypeBrightness ||
                $0.characteristicType == HMCharacteristicTypeCurrentTemperature
            })
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    Image(systemName: iconForAccessory(accessory))
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(accessory.name)
                            .font(.largeTitle)
                            .bold()
                        Text(accessory.room?.name ?? "No Room")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                VStack(alignment: .leading, spacing: 30) {
                    Text("Services")
                        .font(.title2)
                        .padding(.horizontal, 80)

                    if controllableServices.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("No Controllable Services")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                    } else {
                        ForEach(controllableServices, id: \.uniqueIdentifier) { service in
                            // Enhanced controls based on service type
                            if service.serviceType == HMServiceTypeThermostat {
                                ThermostatControlView(service: service)
                                    .padding(.horizontal, 80)
                            } else if service.serviceType == HMServiceTypeFan {
                                FanControlView(service: service)
                                    .padding(.horizontal, 80)
                            } else if service.serviceType == HMServiceTypeLockMechanism {
                                LockControlView(service: service)
                                    .padding(.horizontal, 80)
                            } else if service.serviceType == HMServiceTypeWindowCovering {
                                WindowCoveringControlView(service: service)
                                    .padding(.horizontal, 80)
                            } // Commented out missing control views
                            // else if service.serviceType == HMServiceTypeGarageDoorOpener {
                            //     GarageDoorControlView(service: service)
                            //         .padding(.horizontal, 80)
                            // } else if service.serviceType == HMServiceTypeSecuritySystem {
                            //     SecuritySystemControlView(service: service)
                            //         .padding(.horizontal, 80)
                            // } else if service.serviceType == HMServiceTypeValve {
                            //     IrrigationControlView(service: service)
                            //         .padding(.horizontal, 80)
                            // } else if service.serviceType == HMServiceTypeAirPurifier {
                            //     AirQualityControlView(service: service)
                            //         .padding(.horizontal, 80)
                            else if service.serviceType == HMServiceTypeGarageDoorOpener ||
                                    service.serviceType == HMServiceTypeSecuritySystem ||
                                    service.serviceType == HMServiceTypeValve ||
                                    service.serviceType == HMServiceTypeAirPurifier {
                                Text("Control view not yet implemented")
                                    .padding(.horizontal, 80)
                                    .foregroundColor(.secondary)
                            } else if service.serviceType == HMServiceTypeLightbulb {
                                // Check if it's a color-capable light
                                if service.characteristics.contains(where: { $0.characteristicType == HMCharacteristicTypeHue }) {
                                    ColorControlView(service: service)
                                        .padding(.horizontal, 80)
                                } else {
                                    ServiceDetailCard(service: service, brightnessValue: $brightnessValue)
                                        .padding(.horizontal, 80)
                                }
                            } else {
                                ServiceDetailCard(service: service, brightnessValue: $brightnessValue)
                                    .padding(.horizontal, 80)
                            }
                        }
                    }
                }

                // Sensor Display
                SensorDisplayView(accessory: accessory)
                    .padding(.horizontal, 80)

                VStack(alignment: .leading, spacing: 20) {
                    Text("Information")
                        .font(.title2)
                        .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 16) {
                        InfoRow(label: "Manufacturer", value: accessory.manufacturer ?? "Unknown")
                        InfoRow(label: "Model", value: accessory.model ?? "Unknown")
                        InfoRow(label: "Firmware", value: accessory.firmwareVersion ?? "Unknown")
                        InfoRow(label: "Reachable", value: accessory.isReachable ? "Yes" : "No")
                    }
                    .padding(30)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal, 80)
                }
            }
            .padding(.bottom, 60)
        }
    }

    /// Determines the appropriate SF Symbol icon for an accessory
    ///
    /// Maps HomeKit service types to SF Symbol names.
    ///
    /// - Parameter accessory: The accessory to get an icon for
    /// - Returns: SF Symbol name as string
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

/// Interactive card for controlling a HomeKit service
///
/// Provides controls for a service's characteristics including:
/// - Power state toggle button
/// - Brightness controls for dimmable lights (with +/- buttons)
///
/// **Features**:
/// - Displays service name and type
/// - On/Off toggle with visual feedback
/// - Brightness slider (0-100%) for applicable services
/// - Auto-reads current brightness value on appear
/// - Background color changes based on power state
///
/// **Interaction**:
/// - Tap power button to toggle
/// - Use +/- buttons to adjust brightness in 10% increments
///
/// **Layout**: Card with rounded corners and padding
struct ServiceDetailCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService
    @Binding var brightnessValue: Double
    @FocusState private var isFocused: Bool

    var powerCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
    }

    var brightnessCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
    }

    var isOn: Bool {
        powerCharacteristic?.value as? Bool ?? false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(service.name)
                        .font(.title2)
                    Text(service.serviceType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let _ = powerCharacteristic {
                    Button(action: {
                        homeManager.toggleService(service)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isOn ? "power.circle.fill" : "power.circle")
                                .font(.system(size: 30))
                            Text(isOn ? "On" : "Off")
                                .font(.title3)
                        }
                        .foregroundColor(isOn ? .green : .secondary)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .focused($isFocused)
                }
            }

            if let brightnessChar = brightnessCharacteristic, isOn {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Brightness: \(Int(brightnessValue))%")
                        .font(.title3)

                    HStack(spacing: 30) {
                        Button(action: {
                            let newValue = max(0, brightnessValue - 10)
                            brightnessValue = newValue
                            homeManager.setBrightness(brightnessChar, value: Int(newValue))
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        Text("\(Int(brightnessValue))%")
                            .font(.system(size: 40, weight: .bold))
                            .frame(minWidth: 150)

                        Button(action: {
                            let newValue = min(100, brightnessValue + 10)
                            brightnessValue = newValue
                            homeManager.setBrightness(brightnessChar, value: Int(newValue))
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
                .task {
                    // Read current brightness value
                    do {
                        try await brightnessChar.readValue()
                        if let value = brightnessChar.value as? Int {
                            await MainActor.run {
                                self.brightnessValue = Double(value)
                            }
                        }
                    } catch {
                        // Error reading value
                    }
                }
            }
        }
        .padding(30)
        .background(isOn ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Simple information display row with label and value
///
/// Displays a key-value pair in a horizontal layout.
///
/// **Layout**: Label on left (secondary color), value on right (primary color)
///
/// - Note: Used in accessory information section
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.title3)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.title3)
        }
    }
}
