import SwiftUI
import HomeKit

/// Family controls and parental controls view
struct FamilyControlsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var familyControls = FamilyControlsManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Family Controls")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Kid Mode Toggle
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Kid Mode")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(spacing: 20) {
                            Toggle(isOn: $familyControls.isKidModeActive) {
                                HStack(spacing: 15) {
                                    Image(systemName: "figure.and.child.holdinghands")
                                        .font(.system(size: 30))
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Kid-Friendly Mode")
                                            .font(.title3)
                                            .bold()
                                        Text("Limit controls to approved accessories and scenes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(25)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(15)

                            if familyControls.isKidModeActive {
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Allowed Accessories (\(familyControls.allowedAccessories.count))")
                                        .font(.body)
                                        .bold()

                                    ForEach(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
                                        Toggle(isOn: Binding(
                                            get: { familyControls.isAllowed(accessory) },
                                            set: { _ in familyControls.toggleAccessoryPermission(accessory) }
                                        )) {
                                            Text(accessory.name)
                                                .font(.body)
                                        }
                                        .padding(15)
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(10)
                                    }
                                }
                                .padding(20)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal, 80)
                    }

                    // Bedtime Schedule
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Bedtime Schedule")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        NavigationLink(destination: BedtimeScheduleView()) {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Bedtime Automation")
                                        .font(.title3)
                                        .bold()

                                    if let schedule = familyControls.bedtimeSchedule, schedule.enabled {
                                        Text("Active")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else {
                                        Text("Not configured")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(25)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 80)
                    }

                    // Safety Tips
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Safety Tips")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        VStack(alignment: .leading, spacing: 15) {
                            SafetyTip(
                                icon: "lock.fill",
                                text: "Always allow access to essential devices like door locks"
                            )

                            SafetyTip(
                                icon: "thermometer",
                                text: "Keep thermostats accessible for comfort and safety"
                            )

                            SafetyTip(
                                icon: "lightbulb.fill",
                                text: "Allow bedroom lights for nighttime safety"
                            )
                        }
                        .padding(25)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// Bedtime schedule configuration view
struct BedtimeScheduleView: View {
    @ObservedObject private var familyControls = FamilyControlsManager.shared

    @State private var enabled: Bool
    @State private var bedtime: Date
    @State private var wakeTime: Date
    @State private var turnOffLights: Bool
    @State private var lockDoors: Bool
    @State private var adjustThermostat: Bool
    @State private var nightTemperature: Int

    init() {
        let schedule = FamilyControlsManager.shared.bedtimeSchedule ?? BedtimeSchedule(
            enabled: false,
            bedtime: Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
            wakeTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
            turnOffLights: true,
            lockDoors: true,
            adjustThermostat: false,
            nightTemperature: 68,
            enabledDays: [1, 2, 3, 4, 5, 6, 7]
        )

        _enabled = State(initialValue: schedule.enabled)
        _bedtime = State(initialValue: schedule.bedtime)
        _wakeTime = State(initialValue: schedule.wakeTime)
        _turnOffLights = State(initialValue: schedule.turnOffLights)
        _lockDoors = State(initialValue: schedule.lockDoors)
        _adjustThermostat = State(initialValue: schedule.adjustThermostat)
        _nightTemperature = State(initialValue: schedule.nightTemperature ?? 68)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Bedtime Schedule")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 60)

                Toggle(isOn: $enabled) {
                    HStack {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 30))
                        Text("Enable Bedtime Schedule")
                            .font(.title3)
                    }
                }
                .padding(25)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(15)

                if enabled {
                    VStack(alignment: .leading, spacing: 25) {
                        // Times
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Schedule")
                                .font(.title3)
                                .bold()

                            HStack {
                                Text("Bedtime:")
                                Spacer()
                                Text(bedtime, style: .time)
                                    .font(.title3)
                            }

                            HStack {
                                Text("Wake Time:")
                                Spacer()
                                Text(wakeTime, style: .time)
                                    .font(.title3)
                            }
                        }
                        .padding(20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)

                        // Actions
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Bedtime Actions")
                                .font(.title3)
                                .bold()

                            Toggle(isOn: $turnOffLights) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                    Text("Turn off all lights")
                                }
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)

                            Toggle(isOn: $lockDoors) {
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Lock all doors")
                                }
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)

                            Toggle(isOn: $adjustThermostat) {
                                HStack {
                                    Image(systemName: "thermometer")
                                    Text("Adjust thermostats to \(nightTemperature)°")
                                }
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)

                            if adjustThermostat {
                                HStack {
                                    Text("Night Temperature: \(nightTemperature)°")
                                        .font(.body)

                                    Spacer()

                                    Button(action: {
                                        nightTemperature = max(60, nightTemperature - 1)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 30))
                                    }
                                    .buttonStyle(.plain)

                                    Button(action: {
                                        nightTemperature = min(80, nightTemperature + 1)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 30))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(15)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(10)
                            }
                        }
                        .padding(20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }

                Button("Save Schedule") {
                    let schedule = BedtimeSchedule(
                        enabled: enabled,
                        bedtime: bedtime,
                        wakeTime: wakeTime,
                        turnOffLights: turnOffLights,
                        lockDoors: lockDoors,
                        adjustThermostat: adjustThermostat,
                        nightTemperature: nightTemperature,
                        enabledDays: [1, 2, 3, 4, 5, 6, 7]
                    )
                    familyControls.bedtimeSchedule = schedule
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 80)
        }
    }
}

/// Safety tip row
struct SafetyTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 25))
                .foregroundColor(.orange)
                .frame(width: 40)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    FamilyControlsView()
        .environmentObject(HomeKitManager())
}
