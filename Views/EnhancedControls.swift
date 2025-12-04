import SwiftUI
import HomeKit

// MARK: - Thermostat Controls

/// Enhanced thermostat control view with temperature and mode adjustment
struct ThermostatControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var targetTemp: Double = 70
    @State private var currentMode: Int = 0

    var currentTemp: Double? {
        homeManager.getCurrentTemperature(service)
    }

    var targetTemperature: Double? {
        homeManager.getTargetTemperature(service)
    }

    let modes = ["Off", "Heat", "Cool", "Auto"]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Thermostat Control")
                .font(.title2)
                .bold()

            // Current Temperature Display
            if let current = currentTemp {
                HStack {
                    Image(systemName: "thermometer")
                        .font(.system(size: 40))
                    VStack(alignment: .leading) {
                        Text("Current Temperature")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(current))°")
                            .font(.system(size: 40, weight: .bold))
                    }
                }
                .padding(20)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(15)
            }

            // Target Temperature Control
            VStack(alignment: .leading, spacing: 20) {
                Text("Target Temperature: \(Int(targetTemp))°")
                    .font(.title3)

                HStack(spacing: 40) {
                    Button(action: {
                        targetTemp = max(50, targetTemp - 1)
                        homeManager.setTargetTemperature(service, temperature: targetTemp) { _ in }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(targetTemp))°")
                        .font(.system(size: 50, weight: .bold))
                        .frame(minWidth: 120)

                    Button(action: {
                        targetTemp = min(90, targetTemp + 1)
                        homeManager.setTargetTemperature(service, temperature: targetTemp) { _ in }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Mode Selection
            VStack(alignment: .leading, spacing: 20) {
                Text("Mode")
                    .font(.title3)

                HStack(spacing: 20) {
                    ForEach(0..<modes.count, id: \.self) { index in
                        Button(action: {
                            currentMode = index
                            homeManager.setThermostatMode(service, mode: index) { _ in }
                        }) {
                            Text(modes[index])
                                .font(.title3)
                                .foregroundColor(currentMode == index ? .white : .primary)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(currentMode == index ? Color.blue : Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .onAppear {
            if let temp = targetTemperature {
                targetTemp = temp
            }
        }
    }
}

// MARK: - Color Controls

/// Color control view for color-capable lights
struct ColorControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var hue: Double = 0
    @State private var saturation: Double = 100
    @State private var brightness: Double = 100

    var hueCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeHue })
    }

    var saturationCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeSaturation })
    }

    var brightnessCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
    }

    let presetColors: [(String, Double, Double)] = [
        ("Warm White", 30, 20),
        ("Cool White", 210, 20),
        ("Red", 0, 100),
        ("Orange", 30, 100),
        ("Yellow", 60, 100),
        ("Green", 120, 100),
        ("Cyan", 180, 100),
        ("Blue", 240, 100),
        ("Purple", 270, 100),
        ("Pink", 300, 100)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Color Control")
                .font(.title2)
                .bold()

            // Color Preview
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hue: hue / 360, saturation: saturation / 100, brightness: brightness / 100))
                .frame(height: 100)
                .overlay(
                    Text("Current Color")
                        .font(.title3)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                )

            // Hue Control
            VStack(alignment: .leading, spacing: 15) {
                Text("Hue: \(Int(hue))°")
                    .font(.title3)

                HStack(spacing: 30) {
                    Button(action: {
                        hue = max(0, hue - 10)
                        if let char = hueCharacteristic {
                            homeManager.setHue(char, value: hue) { _ in }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 50))
                    }
                    .buttonStyle(.plain)

                    // Hue gradient bar
                    LinearGradient(
                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 40)
                    .cornerRadius(10)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 30, height: 30)
                            .offset(x: CGFloat((hue / 360) * 600 - 300))
                    )
                    .frame(width: 600)

                    Button(action: {
                        hue = min(360, hue + 10)
                        if let char = hueCharacteristic {
                            homeManager.setHue(char, value: hue) { _ in }
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Saturation Control
            VStack(alignment: .leading, spacing: 15) {
                Text("Saturation: \(Int(saturation))%")
                    .font(.title3)

                HStack(spacing: 30) {
                    Button(action: {
                        saturation = max(0, saturation - 10)
                        if let char = saturationCharacteristic {
                            homeManager.setSaturation(char, value: saturation) { _ in }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 50))
                    }
                    .buttonStyle(.plain)

                    Text("\(Int(saturation))%")
                        .font(.system(size: 40, weight: .bold))
                        .frame(minWidth: 150)

                    Button(action: {
                        saturation = min(100, saturation + 10)
                        if let char = saturationCharacteristic {
                            homeManager.setSaturation(char, value: saturation) { _ in }
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Preset Colors
            VStack(alignment: .leading, spacing: 20) {
                Text("Preset Colors")
                    .font(.title3)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
                    ForEach(presetColors, id: \.0) { color in
                        Button(action: {
                            hue = color.1
                            saturation = color.2
                            if let hueChar = hueCharacteristic {
                                homeManager.setHue(hueChar, value: hue) { _ in }
                            }
                            if let satChar = saturationCharacteristic {
                                homeManager.setSaturation(satChar, value: saturation) { _ in }
                            }
                        }) {
                            VStack(spacing: 10) {
                                Circle()
                                    .fill(Color(hue: color.1 / 360, saturation: color.2 / 100, brightness: 1.0))
                                    .frame(width: 60, height: 60)
                                Text(color.0)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .onAppear {
            // Load current values
            if let hueChar = hueCharacteristic {
                hueChar.readValue { _ in
                    if let value = hueChar.value as? Double {
                        hue = value
                    }
                }
            }
            if let satChar = saturationCharacteristic {
                satChar.readValue { _ in
                    if let value = satChar.value as? Double {
                        saturation = value
                    }
                }
            }
        }
    }
}

// MARK: - Fan Controls

/// Fan control view with speed and direction
struct FanControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var speed: Double = 50
    @State private var isClockwise: Bool = true

    var speedCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeRotationSpeed })
    }

    var directionCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeRotationDirection })
    }

    let speedPresets: [(String, Double)] = [
        ("Off", 0),
        ("Low", 25),
        ("Medium", 50),
        ("High", 75),
        ("Max", 100)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Fan Control")
                .font(.title2)
                .bold()

            // Speed Control
            VStack(alignment: .leading, spacing: 20) {
                Text("Speed: \(Int(speed))%")
                    .font(.title3)

                HStack(spacing: 40) {
                    Button(action: {
                        speed = max(0, speed - 10)
                        if let char = speedCharacteristic {
                            homeManager.setFanSpeed(char, speed: speed) { _ in }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 10) {
                        Image(systemName: "fan.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(speed > 0 ? 360 : 0))

                        Text("\(Int(speed))%")
                            .font(.system(size: 40, weight: .bold))
                    }
                    .frame(minWidth: 200)

                    Button(action: {
                        speed = min(100, speed + 10)
                        if let char = speedCharacteristic {
                            homeManager.setFanSpeed(char, speed: speed) { _ in }
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Speed Presets
            VStack(alignment: .leading, spacing: 20) {
                Text("Speed Presets")
                    .font(.title3)

                HStack(spacing: 20) {
                    ForEach(speedPresets, id: \.0) { preset in
                        Button(action: {
                            speed = preset.1
                            if let char = speedCharacteristic {
                                homeManager.setFanSpeed(char, speed: speed) { _ in }
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(preset.0)
                                    .font(.title3)
                                Text("\(Int(preset.1))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 25)
                            .padding(.vertical, 15)
                            .background(speed == preset.1 ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(speed == preset.1 ? .white : .primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Direction Control
            if directionCharacteristic != nil {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Rotation Direction")
                        .font(.title3)

                    HStack(spacing: 30) {
                        Button(action: {
                            isClockwise = true
                            if let char = directionCharacteristic {
                                homeManager.setFanRotationDirection(char, clockwise: true) { _ in }
                            }
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .font(.system(size: 60))
                                Text("Clockwise")
                                    .font(.title3)
                            }
                            .padding(30)
                            .background(isClockwise ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(isClockwise ? .white : .primary)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            isClockwise = false
                            if let char = directionCharacteristic {
                                homeManager.setFanRotationDirection(char, clockwise: false) { _ in }
                            }
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 60))
                                Text("Counter-Clockwise")
                                    .font(.title3)
                            }
                            .padding(30)
                            .background(!isClockwise ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(!isClockwise ? .white : .primary)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
}

// MARK: - Lock Controls

/// Lock control view with authentication
struct LockControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var showingConfirmation = false
    @State private var pendingLockState: Bool = false

    var isLocked: Bool? {
        homeManager.getLockState(service)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Lock Control")
                .font(.title2)
                .bold()

            VStack(spacing: 30) {
                // Current Status
                HStack(spacing: 20) {
                    Image(systemName: (isLocked ?? false) ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 80))
                        .foregroundColor((isLocked ?? false) ? .green : .red)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text((isLocked ?? false) ? "Locked" : "Unlocked")
                            .font(.system(size: 40, weight: .bold))
                    }
                }
                .padding(30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)

                // Lock/Unlock Buttons
                HStack(spacing: 40) {
                    Button(action: {
                        pendingLockState = true
                        showingConfirmation = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 60))
                            Text("Lock")
                                .font(.title2)
                        }
                        .padding(40)
                        .frame(width: 250, height: 250)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        pendingLockState = false
                        showingConfirmation = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 60))
                            Text("Unlock")
                                .font(.title2)
                        }
                        .padding(40)
                        .frame(width: 250, height: 250)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .alert("Confirm Action", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(pendingLockState ? "Lock" : "Unlock", role: .destructive) {
                homeManager.setLockState(service, locked: pendingLockState) { _ in }
            }
        } message: {
            Text("Are you sure you want to \(pendingLockState ? "lock" : "unlock") this device?")
        }
    }
}

// MARK: - Window Covering Controls

/// Window covering position control
struct WindowCoveringControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var position: Int = 50

    var positionCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetPosition })
    }

    let positionPresets: [(String, Int)] = [
        ("Closed", 0),
        ("25%", 25),
        ("50%", 50),
        ("75%", 75),
        ("Open", 100)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Window Covering Control")
                .font(.title2)
                .bold()

            // Position Control
            VStack(alignment: .leading, spacing: 20) {
                Text("Position: \(position)%")
                    .font(.title3)

                HStack(spacing: 40) {
                    Button(action: {
                        position = max(0, position - 10)
                        if let char = positionCharacteristic {
                            homeManager.setWindowCoveringPosition(char, position: position) { _ in }
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 15) {
                        // Visual representation
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 3)
                                .frame(width: 150, height: 200)

                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.5))
                                .frame(width: 150, height: CGFloat(position) * 2)
                        }

                        Text("\(position)%")
                            .font(.system(size: 40, weight: .bold))
                    }

                    Button(action: {
                        position = min(100, position + 10)
                        if let char = positionCharacteristic {
                            homeManager.setWindowCoveringPosition(char, position: position) { _ in }
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Position Presets
            VStack(alignment: .leading, spacing: 20) {
                Text("Position Presets")
                    .font(.title3)

                HStack(spacing: 20) {
                    ForEach(positionPresets, id: \.0) { preset in
                        Button(action: {
                            position = preset.1
                            if let char = positionCharacteristic {
                                homeManager.setWindowCoveringPosition(char, position: position) { _ in }
                            }
                        }) {
                            Text(preset.0)
                                .font(.title3)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(position == preset.1 ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(position == preset.1 ? .white : .primary)
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
        .onAppear {
            if let currentPosition = homeManager.getWindowCoveringPosition(service) {
                position = currentPosition
            }
        }
    }
}

// MARK: - Sensor Display View

/// View for displaying all sensor readings
struct SensorDisplayView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let accessory: HMAccessory

    var sensorReadings: [String: Any] {
        homeManager.getSensorReadings(accessory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Sensor Readings")
                .font(.title2)
                .bold()

            if sensorReadings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "sensor.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No sensor data available")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(60)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 30)], spacing: 30) {
                    ForEach(Array(sensorReadings.keys.sorted()), id: \.self) { key in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(sensorReadings[key] as? String ?? "")")
                                .font(.system(size: 30, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(25)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                    }
                }
            }
        }
    }
}
