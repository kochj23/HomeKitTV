import SwiftUI
import HomeKit

/// Custom characteristic access view for advanced users
///
/// Provides low-level access to all characteristics including:
/// - View all characteristics (standard and custom)
/// - Read raw characteristic values
/// - Write custom values
/// - Debug mode for developers
/// - API explorer
struct CustomCharacteristicsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var selectedAccessory: HMAccessory?
    @State private var showingDevMode = UserDefaults.standard.bool(forKey: "developerMode")

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Custom Characteristics")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Toggle(isOn: $showingDevMode) {
                            HStack {
                                Image(systemName: "hammer.fill")
                                Text("Developer Mode")
                            }
                            .font(.title3)
                        }
                        .onChange(of: showingDevMode) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "developerMode")
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    if showingDevMode {
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Warning: Modifying characteristics directly can cause unexpected behavior. Use caution.")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(25)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }

                    // Accessory Selection
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Select Accessory")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        ForEach(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
                            Button(action: {
                                selectedAccessory = accessory
                            }) {
                                HStack {
                                    Image(systemName: iconForAccessory(accessory))
                                        .font(.system(size: 30))
                                        .foregroundColor(.blue)
                                        .frame(width: 50)

                                    Text(accessory.name)
                                        .font(.title3)

                                    Spacer()

                                    if selectedAccessory?.uniqueIdentifier == accessory.uniqueIdentifier {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 30))
                                    }
                                }
                                .padding(20)
                                .background(selectedAccessory?.uniqueIdentifier == accessory.uniqueIdentifier ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Characteristics Display
                    if let accessory = selectedAccessory {
                        VStack(alignment: .leading, spacing: 30) {
                            Text("Services & Characteristics")
                                .font(.title2)
                                .padding(.horizontal, 80)

                            ForEach(accessory.services, id: \.uniqueIdentifier) { service in
                                ServiceCharacteristicsView(service: service, devMode: showingDevMode)
                                    .padding(.horizontal, 80)
                            }
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let primaryService = accessory.services.first else {
            return "circle.fill"
        }

        switch primaryService.serviceType {
        case HMServiceTypeLightbulb: return "lightbulb.fill"
        case HMServiceTypeOutlet: return "poweroutlet.type.b.fill"
        case HMServiceTypeSwitch: return "light.switch.on.fill"
        case HMServiceTypeThermostat: return "thermometer"
        case HMServiceTypeFan: return "fan.fill"
        case HMServiceTypeLockMechanism: return "lock.fill"
        default: return "circle.fill"
        }
    }
}

/// Service characteristics detail view
struct ServiceCharacteristicsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService
    let devMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Service Header
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.title3)
                        .bold()

                    Text(service.serviceType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 10)

            // Characteristics
            VStack(spacing: 15) {
                ForEach(service.characteristics, id: \.uniqueIdentifier) { characteristic in
                    CharacteristicRow(characteristic: characteristic, devMode: devMode)
                }
            }
        }
        .padding(25)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Individual characteristic row
struct CharacteristicRow: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let characteristic: HMCharacteristic
    let devMode: Bool

    @State private var currentValue: String = "..."
    @State private var newValue: String = ""
    @State private var isEditing = false

    var characteristicName: String {
        if !characteristic.localizedDescription.isEmpty {
            return characteristic.localizedDescription
        }
        return characteristic.characteristicType
    }

    var isReadable: Bool {
        characteristic.properties.contains(HMCharacteristicPropertyReadable)
    }

    var isWritable: Bool {
        characteristic.properties.contains(HMCharacteristicPropertyWritable)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(characteristicName)
                        .font(.body)
                        .bold()

                    if devMode {
                        Text(characteristic.characteristicType)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospaced()
                    }
                }

                Spacer()

                HStack(spacing: 15) {
                    // Properties badges
                    if isReadable {
                        Text("R")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                    }

                    if isWritable {
                        Text("W")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(6)
                    }

                    // Value display
                    Text(currentValue)
                        .font(.body)
                        .bold()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Write controls (if developer mode and writable)
            if devMode && isWritable {
                HStack(spacing: 15) {
                    TextField("New value", text: $newValue)
                        .font(.body)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)

                    Button("Write") {
                        writeValue()
                    }
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(newValue.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .buttonStyle(.plain)
                    .disabled(newValue.isEmpty)

                    Button("Read") {
                        readValue()
                    }
                    .font(.body)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .buttonStyle(.plain)
                }
            }

            // Metadata (if developer mode)
            if devMode {
                VStack(alignment: .leading, spacing: 6) {
                    if let metadata = characteristic.metadata {
                        if let format = metadata.format {
                            Text("Format: \(format)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let minValue = metadata.minimumValue {
                            Text("Min: \(minValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let maxValue = metadata.maximumValue {
                            Text("Max: \(maxValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let stepValue = metadata.stepValue {
                            Text("Step: \(stepValue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        if let units = metadata.units {
                            Text("Units: \(units)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 5)
            }
        }
        .padding(15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .onAppear {
            if isReadable {
                readValue()
            }
        }
    }

    private func readValue() {
        characteristic.readValue { error in
            DispatchQueue.main.async {
                if let error = error {
                    currentValue = "Error: \(error.localizedDescription)"
                } else if let value = characteristic.value {
                    currentValue = String(describing: value)
                } else {
                    currentValue = "nil"
                }
            }
        }
    }

    private func writeValue() {
        // Parse value based on type
        var valueToWrite: Any?

        if let boolValue = Bool(newValue) {
            valueToWrite = boolValue as NSNumber
        } else if let intValue = Int(newValue) {
            valueToWrite = intValue as NSNumber
        } else if let doubleValue = Double(newValue) {
            valueToWrite = doubleValue as NSNumber
        } else {
            valueToWrite = newValue as NSString
        }

        guard let value = valueToWrite, let copyableValue = value as? NSCopying else {
            homeManager.statusMessage = "Invalid value format"
            return
        }

        characteristic.writeValue(copyableValue) { error in
            DispatchQueue.main.async {
                if let error = error {
                    homeManager.statusMessage = "Write error: \(error.localizedDescription)"
                } else {
                    homeManager.statusMessage = "Value written successfully"
                    newValue = ""
                    readValue()
                }
            }
        }
    }
}

#Preview {
    CustomCharacteristicsView()
        .environmentObject(HomeKitManager())
}
