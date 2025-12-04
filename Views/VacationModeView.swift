import SwiftUI

/// Vacation mode configuration and control
struct VacationModeView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var vacationMode = VacationModeManager.shared

    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7) // 1 week
    @State private var showingActivateConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vacation Mode")
                                .font(.largeTitle)
                                .bold()

                            if vacationMode.isActive, let settings = vacationMode.vacationSettings {
                                Text("Active until \(settings.endDate.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        Spacer()

                        if vacationMode.isActive {
                            Button(action: {
                                vacationMode.deactivateVacationMode(homeManager: homeManager)
                            }) {
                                HStack {
                                    Image(systemName: "stop.circle.fill")
                                    Text("Deactivate")
                                }
                                .font(.title3)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 12)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                showingActivateConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "airplane")
                                    Text("Activate")
                                }
                                .font(.title3)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    // Status
                    if vacationMode.isActive {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Vacation Mode Active")
                                        .font(.title2)
                                        .bold()
                                    Text("Your home is being protected")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(30)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)

                            // Active Features
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Active Features:")
                                    .font(.title3)
                                    .bold()

                                FeatureRow(icon: "lightbulb.fill", text: "Light randomization (\(vacationMode.lightSchedule.count) lights)", active: true)
                                FeatureRow(icon: "thermometer", text: "Thermostat set to savings mode", active: vacationMode.vacationSettings?.adjustThermostat ?? false)
                                FeatureRow(icon: "lock.fill", text: "All doors locked", active: vacationMode.vacationSettings?.lockDoors ?? false)
                                FeatureRow(icon: "video.fill", text: "Enhanced camera recording", active: vacationMode.vacationSettings?.increaseCameraRecording ?? false)
                            }
                            .padding(25)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(15)
                        }
                        .padding(.horizontal, 80)
                    }

                    // Configuration (when inactive)
                    if !vacationMode.isActive {
                        VStack(alignment: .leading, spacing: 30) {
                            Text("Configuration")
                                .font(.title2)
                                .padding(.horizontal, 80)

                            VStack(alignment: .leading, spacing: 20) {
                                // Dates
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("Vacation Dates")
                                        .font(.title3)
                                        .bold()

                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Start")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(startDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.title3)
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.right")

                                        Spacer()

                                        VStack(alignment: .trailing) {
                                            Text("End")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(endDate.formatted(date: .abbreviated, time: .omitted))
                                                .font(.title3)
                                        }
                                    }
                                }
                                .padding(25)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(15)

                                // Features Preview
                                VStack(alignment: .leading, spacing: 15) {
                                    Text("What Vacation Mode Does:")
                                        .font(.title3)
                                        .bold()

                                    FeatureDescription(
                                        icon: "lightbulb.fill",
                                        title: "Randomize Lights",
                                        description: "Turn lights on/off at random times to simulate presence"
                                    )

                                    FeatureDescription(
                                        icon: "thermometer",
                                        title: "Energy Savings",
                                        description: "Reduce heating/cooling to save energy"
                                    )

                                    FeatureDescription(
                                        icon: "lock.fill",
                                        title: "Security",
                                        description: "Lock all doors and enable enhanced monitoring"
                                    )

                                    FeatureDescription(
                                        icon: "video.fill",
                                        title: "Camera Recording",
                                        description: "Increase camera sensitivity and recording"
                                    )
                                }
                                .padding(25)
                                .background(Color.purple.opacity(0.05))
                                .cornerRadius(15)
                            }
                            .padding(.horizontal, 80)
                        }
                    }

                    // Light Schedule (when active)
                    if vacationMode.isActive && !vacationMode.lightSchedule.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Light Schedule")
                                .font(.title2)
                                .padding(.horizontal, 80)

                            ForEach(vacationMode.lightSchedule.prefix(10), id: \.accessoryID) { schedule in
                                HStack {
                                    Text(schedule.accessoryName)
                                        .font(.body)

                                    Spacer()

                                    Text("\(schedule.onTime.hour):\(String(format: "%02d", schedule.onTime.minute)) - \(schedule.offTime.hour):\(String(format: "%02d", schedule.offTime.minute))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .monospaced()
                                }
                                .padding(15)
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 80)

                            if vacationMode.lightSchedule.count > 10 {
                                Text("+ \(vacationMode.lightSchedule.count - 10) more lights")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 80)
                            }
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .alert("Activate Vacation Mode", isPresented: $showingActivateConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Activate") {
                vacationMode.activateVacationMode(
                    startDate: startDate,
                    endDate: endDate,
                    homeManager: homeManager
                )
            }
        } message: {
            Text("This will lock doors, adjust thermostats, and randomize lights to simulate presence.")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let active: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                .foregroundColor(active ? .green : .gray)
            Image(systemName: icon)
                .foregroundColor(active ? .blue : .gray)
            Text(text)
                .font(.body)
                .foregroundColor(active ? .primary : .secondary)
        }
    }
}

struct FeatureDescription: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.purple)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    VacationModeView()
        .environmentObject(HomeKitManager())
}
