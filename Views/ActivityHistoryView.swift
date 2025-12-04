import SwiftUI

/// Activity history view showing recent actions
struct ActivityHistoryView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var filterText = ""
    @State private var showingClearConfirmation = false

    var filteredHistory: [ActivityEntry] {
        let history = homeManager.getActivityHistory()
        guard !filterText.isEmpty else { return history }
        return history.filter {
            $0.action.localizedCaseInsensitiveContains(filterText) ||
            $0.accessoryName.localizedCaseInsensitiveContains(filterText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Activity History")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All")
                            }
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    // Filter/Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 25))
                            .foregroundColor(.secondary)

                        TextField("Filter activities...", text: $filterText)
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .textFieldStyle(.plain)
                    }
                    .padding(25)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)

                    // Activity List
                    if filteredHistory.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text(filterText.isEmpty ? "No activity history" : "No matching activities")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(filteredHistory) { entry in
                                ActivityEntryRow(entry: entry)
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .alert("Clear History", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                homeManager.clearActivityHistory()
            }
        } message: {
            Text("Are you sure you want to clear all activity history? This action cannot be undone.")
        }
    }
}

/// Individual activity entry row
struct ActivityEntryRow: View {
    let entry: ActivityEntry

    var iconName: String {
        switch entry.action {
        case let action where action.contains("Lock"):
            return "lock.fill"
        case let action where action.contains("Unlock"):
            return "lock.open.fill"
        case let action where action.contains("Temperature"):
            return "thermometer"
        case let action where action.contains("Brightness"):
            return "sun.max.fill"
        case let action where action.contains("Color"), let action where action.contains("Hue"), let action where action.contains("Saturation"):
            return "paintpalette.fill"
        case let action where action.contains("Fan"):
            return "fan.fill"
        case let action where action.contains("Window"):
            return "window.vertical.closed"
        case let action where action.contains("Scene"):
            return "sparkles"
        case let action where action.contains("Automation"):
            return "gearshape.2.fill"
        default:
            return "power.circle.fill"
        }
    }

    var iconColor: Color {
        switch entry.action {
        case let action where action.contains("Lock"):
            return .green
        case let action where action.contains("Unlock"):
            return .red
        case let action where action.contains("Error"), let action where action.contains("Failed"):
            return .red
        case let action where action.contains("Scene"):
            return .orange
        default:
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(iconColor)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.action)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Text(entry.accessoryName)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)

                if let details = entry.details {
                    Text(details)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }

                Text(entry.relativeTime)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(entry.formattedTime)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

#Preview {
    ActivityHistoryView()
        .environmentObject(HomeKitManager())
}
