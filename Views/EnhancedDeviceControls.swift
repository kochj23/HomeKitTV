import SwiftUI
import HomeKit

// MARK: - Garage Door Controls

/// Garage door control view with safety features
struct GarageDoorControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var showingOpenConfirmation = false
    @State private var showingCloseConfirmation = false
    @State private var position: Int = 0
    @State private var isObstructed: Bool = false

    var targetDoorState: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetDoorState })
    }

    var currentDoorState: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentDoorState })
    }

    var obstructionDetected: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeObstructionDetected })
    }

    var doorState: String {
        guard let currentState = currentDoorState?.value as? Int else { return "Unknown" }
        switch currentState {
        case 0: return "Open"
        case 1: return "Closed"
        case 2: return "Opening"
        case 3: return "Closing"
        case 4: return "Stopped"
        default: return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Garage Door Control")
                .font(.title2)
                .bold()

            // Current Status
            VStack(spacing: 25) {
                HStack(spacing: 20) {
                    Image(systemName: iconForState)
                        .font(.system(size: 80))
                        .foregroundColor(colorForState)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(doorState)
                            .font(.system(size: 40, weight: .bold))
                    }
                }
                .padding(30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)

                // Obstruction Warning
                if isObstructed {
                    HStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.red)
                        Text("Obstruction Detected - Check door path before operating")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .padding(20)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(15)
                }

                // Control Buttons
                HStack(spacing: 40) {
                    Button(action: {
                        showingOpenConfirmation = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 60))
                            Text("Open")
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
                        showingCloseConfirmation = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 60))
                            Text("Close")
                                .font(.title2)
                        }
                        .padding(40)
                        .frame(width: 250, height: 250)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .alert("Open Garage Door", isPresented: $showingOpenConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Open") {
                setDoorState(0) // 0 = open
            }
        } message: {
            Text("Make sure the path is clear before opening the garage door.")
        }
        .alert("Close Garage Door", isPresented: $showingCloseConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Close") {
                setDoorState(1) // 1 = closed
            }
        } message: {
            Text("Make sure nothing is in the way before closing the garage door.")
        }
        .onAppear {
            readObstructionStatus()
        }
    }

    var iconForState: String {
        switch doorState {
        case "Open": return "garage.open.fill"
        case "Closed": return "garage.closed.fill"
        case "Opening", "Closing": return "arrow.left.arrow.right.circle.fill"
        case "Stopped": return "pause.circle.fill"
        default: return "garage.fill"
        }
    }

    var colorForState: Color {
        switch doorState {
        case "Open": return .green
        case "Closed": return .blue
        case "Opening", "Closing": return .orange
        case "Stopped": return .red
        default: return .gray
        }
    }

    private func setDoorState(_ state: Int) {
        guard let targetChar = targetDoorState else { return }

        targetChar.writeValue(state) { [self] error in
            DispatchQueue.main.async {
                if let error = error {
                    homeManager.statusMessage = "Garage error: \(error.localizedDescription)"
                } else {
                    homeManager.statusMessage = "Garage door \(state == 0 ? "opening" : "closing")"
                }
            }
        }
    }

    private func readObstructionStatus() {
        obstructionDetected?.readValue { [self] _ in
            DispatchQueue.main.async {
                isObstructed = (obstructionDetected?.value as? Bool) ?? false
            }
        }
    }
}

// MARK: - Security System Controls

/// Security system control view
struct SecuritySystemControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var currentState: Int = 0
    @State private var showingPINEntry = false
    @State private var pinCode = ""

    var targetStateCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetSecuritySystemState })
    }

    var currentStateCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeCurrentSecuritySystemState })
    }

    let modes = [
        (0, "Stay", "Home mode - perimeter protection", "house.fill", Color.green),
        (1, "Away", "Full protection - all sensors", "figure.walk", Color.orange),
        (2, "Night", "Sleep mode - entry points", "moon.stars.fill", Color.purple),
        (3, "Disarm", "System off", "shield.slash", Color.blue)
    ]

    var currentModeName: String {
        switch currentState {
        case 0: return "Stay"
        case 1: return "Away"
        case 2: return "Night"
        case 3: return "Disarmed"
        case 4: return "Triggered"
        default: return "Unknown"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Security System")
                .font(.title2)
                .bold()

            // Current Status
            HStack(spacing: 20) {
                Image(systemName: currentState == 4 ? "bell.fill" : "shield.fill")
                    .font(.system(size: 70))
                    .foregroundColor(currentState == 4 ? .red : colorForMode(currentState))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currentModeName)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(currentState == 4 ? .red : .primary)
                }

                Spacer()

                if currentState == 4 {
                    Button(action: {
                        // Trigger panic/emergency
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                            Text("ALARM")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .padding(25)
                        .background(Color.red)
                        .cornerRadius(15)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background((currentState == 4 ? Color.red : Color.gray).opacity(0.1))
            .cornerRadius(20)

            // Mode Selection
            VStack(spacing: 20) {
                ForEach(modes, id: \.0) { mode in
                    Button(action: {
                        setSecurityMode(mode.0)
                    }) {
                        HStack(spacing: 20) {
                            Image(systemName: mode.3)
                                .font(.system(size: 40))
                                .foregroundColor(mode.4)
                                .frame(width: 60)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(mode.1)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.primary)

                                Text(mode.2)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if currentState == mode.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(25)
                        .background(mode.4.opacity(0.1))
                        .cornerRadius(15)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            readCurrentState()
        }
    }

    private func colorForMode(_ mode: Int) -> Color {
        switch mode {
        case 0: return .green
        case 1: return .orange
        case 2: return .purple
        case 3: return .blue
        case 4: return .red
        default: return .gray
        }
    }

    private func setSecurityMode(_ mode: Int) {
        guard let targetChar = targetStateCharacteristic else { return }

        targetChar.writeValue(mode) { [self] error in
            DispatchQueue.main.async {
                if let error = error {
                    homeManager.statusMessage = "Security error: \(error.localizedDescription)"
                } else {
                    let modeName = modes.first { $0.0 == mode }?.1 ?? "Unknown"
                    homeManager.statusMessage = "Security mode set to \(modeName)"
                    currentState = mode
                }
            }
        }
    }

    private func readCurrentState() {
        currentStateCharacteristic?.readValue { [self] _ in
            DispatchQueue.main.async {
                currentState = (currentStateCharacteristic?.value as? Int) ?? 3
            }
        }
    }
}

// MARK: - Irrigation System Controls

/// Irrigation system control view
struct IrrigationControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var selectedZone: Int = 0
    @State private var runTime: Int = 15 // minutes
    @State private var isRunning: Bool = false

    let zones = ["Front Yard", "Back Yard", "Garden", "Side Yard"]
    let runTimeOptions = [5, 10, 15, 20, 30, 45, 60]

    var activeCharacteristic: HMCharacteristic? {
        service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeActive })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Irrigation Control")
                .font(.title2)
                .bold()

            // Status
            HStack(spacing: 20) {
                Image(systemName: isRunning ? "drop.fill" : "drop")
                    .font(.system(size: 60))
                    .foregroundColor(isRunning ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("System Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(isRunning ? "Running" : "Idle")
                        .font(.system(size: 35, weight: .bold))
                }
            }
            .padding(30)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)

            // Zone Selection
            VStack(alignment: .leading, spacing: 15) {
                Text("Select Zone")
                    .font(.title3)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 20)], spacing: 20) {
                    ForEach(0..<zones.count, id: \.self) { index in
                        Button(action: {
                            selectedZone = index
                        }) {
                            VStack(spacing: 10) {
                                Image(systemName: "leaf.fill")
                                    .font(.system(size: 30))
                                Text(zones[index])
                                    .font(.body)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(selectedZone == index ? Color.green : Color.gray.opacity(0.2))
                            .foregroundColor(selectedZone == index ? .white : .primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Run Time
            VStack(alignment: .leading, spacing: 15) {
                Text("Run Time: \(runTime) minutes")
                    .font(.title3)

                HStack(spacing: 15) {
                    ForEach(runTimeOptions, id: \.self) { time in
                        Button(action: {
                            runTime = time
                        }) {
                            Text("\(time)m")
                                .font(.body)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(runTime == time ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(runTime == time ? .white : .primary)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Control Buttons
            HStack(spacing: 30) {
                Button(action: {
                    startIrrigation()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Watering")
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(isRunning ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
                .disabled(isRunning)

                Button(action: {
                    stopIrrigation()
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop")
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(isRunning ? Color.red : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .buttonStyle(.plain)
                .disabled(!isRunning)
            }
        }
    }

    var iconForState: String {
        if isRunning {
            return "drop.triangle.fill"
        }
        return "drop.fill"
    }

    var colorForState: Color {
        if isRunning {
            return .blue
        }
        return .gray
    }

    private func startIrrigation() {
        guard let activeChar = activeCharacteristic else { return }

        activeChar.writeValue(true as NSNumber) { error in
            DispatchQueue.main.async {
                if let error = error {
                    homeManager.statusMessage = "Irrigation error: \(error.localizedDescription)"
                } else {
                    isRunning = true
                    homeManager.statusMessage = "Started watering \(zones[selectedZone])"

                    // Auto-stop after run time
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(runTime * 60)) {
                        stopIrrigation()
                    }
                }
            }
        }
    }

    private func stopIrrigation() {
        guard let activeChar = activeCharacteristic else { return }

        activeChar.writeValue(false as NSNumber) { error in
            DispatchQueue.main.async {
                if let error = error {
                    homeManager.statusMessage = "Stop error: \(error.localizedDescription)"
                } else {
                    isRunning = false
                    homeManager.statusMessage = "Irrigation stopped"
                }
            }
        }
    }
}

// MARK: - Air Quality Device Controls

/// Air purifier and air quality device control
struct AirQualityControlView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let service: HMService

    @State private var fanSpeed: Double = 50
    @State private var mode: Int = 0 // 0 = auto, 1 = manual
    @State private var filterLife: Int = 85 // percentage

    let speedPresets = [
        (0.0, "Off"),
        (25.0, "Low"),
        (50.0, "Medium"),
        (75.0, "High"),
        (100.0, "Max")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Air Purifier Control")
                .font(.title2)
                .bold()

            // Air Quality Display
            HStack(spacing: 30) {
                Image(systemName: "aqi.medium")
                    .font(.system(size: 60))
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Air Quality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Good")
                        .font(.system(size: 35, weight: .bold))
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text("Filter Life")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(filterLife)%")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(filterLife < 20 ? .red : .green)
                }
            }
            .padding(30)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)

            // Mode Selection
            VStack(alignment: .leading, spacing: 15) {
                Text("Mode")
                    .font(.title3)

                HStack(spacing: 20) {
                    Button(action: {
                        mode = 0
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 40))
                            Text("Auto")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 25)
                        .background(mode == 0 ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(mode == 0 ? .white : .primary)
                        .cornerRadius(15)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        mode = 1
                    }) {
                        VStack(spacing: 10) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 40))
                            Text("Manual")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 25)
                        .background(mode == 1 ? Color.orange : Color.gray.opacity(0.2))
                        .foregroundColor(mode == 1 ? .white : .primary)
                        .cornerRadius(15)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)

            // Fan Speed (Manual Mode Only)
            if mode == 1 {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Fan Speed: \(Int(fanSpeed))%")
                        .font(.title3)

                    HStack(spacing: 40) {
                        Button(action: {
                            fanSpeed = max(0, fanSpeed - 25)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                        }
                        .buttonStyle(.plain)

                        Image(systemName: "fan.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Button(action: {
                            fanSpeed = min(100, fanSpeed + 25)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)

                    // Speed Presets
                    HStack(spacing: 15) {
                        ForEach(speedPresets, id: \.0) { preset in
                            Button(action: {
                                fanSpeed = preset.0
                            }) {
                                Text(preset.1)
                                    .font(.body)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(fanSpeed == preset.0 ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(fanSpeed == preset.0 ? .white : .primary)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(30)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(20)
            }

            // Filter Status
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "air.purifier")
                        .font(.system(size: 30))
                    Text("Filter Status")
                        .font(.title3)

                    Spacer()

                    if filterLife < 20 {
                        Text("Replace Soon")
                            .font(.body)
                            .foregroundColor(.red)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(8)
                    }
                }

                ProgressView(value: Double(filterLife) / 100.0)
                    .tint(filterLife < 20 ? .red : .green)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding(30)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(20)
        }
    }
}

