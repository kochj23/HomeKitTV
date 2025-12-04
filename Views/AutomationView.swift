import SwiftUI
import HomeKit

/// Automation management view
struct AutomationView: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var automations: [HMTrigger] {
        homeManager.getAutomations()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Automations")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    if automations.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Automations")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                            Text("Create automations in the Home app on iOS")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(automations, id: \.uniqueIdentifier) { trigger in
                                AutomationRow(trigger: trigger)
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// Individual automation row
struct AutomationRow: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let trigger: HMTrigger
    @State private var isEnabled: Bool

    init(trigger: HMTrigger) {
        self.trigger = trigger
        _isEnabled = State(initialValue: trigger.isEnabled)
    }

    var triggerType: String {
        switch trigger {
        case is HMTimerTrigger:
            return "Timer"
        case is HMEventTrigger:
            return "Event"
        default:
            return "Automation"
        }
    }

    var triggerIcon: String {
        switch trigger {
        case is HMTimerTrigger:
            return "clock.fill"
        case is HMEventTrigger:
            return "bolt.fill"
        default:
            return "gearshape.fill"
        }
    }

    var triggerDetails: String {
        if let timerTrigger = trigger as? HMTimerTrigger {
            let fireDate = timerTrigger.fireDate
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let dateString = formatter.string(from: fireDate)

            if let recurrence = timerTrigger.recurrence {
                return "Fires at \(dateString), repeats \(recurrence.description)"
            }
            return "Fires at \(dateString)"
        } else if let _ = trigger as? HMEventTrigger {
            return "Event-based automation"
        }
        return triggerType
    }

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: triggerIcon)
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(trigger.name)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Text(triggerType)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                Text(triggerDetails)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    homeManager.setAutomationEnabled(trigger, enabled: newValue) { error in
                        if error != nil {
                            // Revert on error
                            isEnabled = !newValue
                        }
                    }
                }
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

#Preview {
    AutomationView()
        .environmentObject(HomeKitManager())
}
