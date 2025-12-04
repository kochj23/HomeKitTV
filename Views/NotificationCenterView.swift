import SwiftUI
import HomeKit

/// Notification Center View
///
/// Comprehensive notification management interface for HomeKit events:
/// - View all HomeKit notifications with timestamps
/// - Filter by type (low battery, motion, temperature, etc.)
/// - Mark as read/unread
/// - Quick actions from notifications
/// - Notification rules management
/// - Priority-based visual indicators
///
/// **Backend Integration**: Uses NotificationManager.shared
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Uses @ObservedObject to prevent retain cycles
///
/// **Security**: Follows user privacy preferences for notifications
/// **Accessibility**: VoiceOver-friendly with clear labels
///
/// - SeeAlso: `NotificationManager`, `HomeNotification`, `NotificationRule`
struct NotificationCenterView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var homeManager: HomeKitManager

    @State private var filterType: NotificationType? = nil
    @State private var showUnreadOnly = false
    @State private var showingRulesEditor = false
    @State private var selectedNotification: HomeNotification?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                headerSection

                // Filters and Actions
                filterSection

                // Statistics
                statisticsSection

                // Notifications List
                notificationsListSection

                // Rules Management
                rulesSection
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
        .sheet(isPresented: $showingRulesEditor) {
            rulesEditorSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notification Center")
                    .font(.largeTitle)
                    .bold()
                HStack {
                    Text("\(notificationManager.notifications.count) notifications")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                    if notificationManager.unreadCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(notificationManager.unreadCount) unread")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.blue)
                            .bold()
                    }
                }
            }

            Spacer()

            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
        }
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Filters")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // All filter
                    FilterButton(
                        title: "All",
                        icon: "circle.grid.3x3.fill",
                        isSelected: filterType == nil,
                        count: notificationManager.notifications.count
                    ) {
                        filterType = nil
                    }

                    // Type filters
                    FilterButton(
                        title: "Low Battery",
                        icon: "battery.25",
                        isSelected: filterType == .lowBattery,
                        count: notificationManager.notifications.filter { $0.type == .lowBattery }.count
                    ) {
                        filterType = .lowBattery
                    }

                    FilterButton(
                        title: "Motion",
                        icon: "figure.walk",
                        isSelected: filterType == .motionDetected,
                        count: notificationManager.notifications.filter { $0.type == .motionDetected }.count
                    ) {
                        filterType = .motionDetected
                    }

                    FilterButton(
                        title: "Door/Window",
                        icon: "door.left.hand.open",
                        isSelected: filterType == .doorOpened,
                        count: notificationManager.notifications.filter { $0.type == .doorOpened }.count
                    ) {
                        filterType = .doorOpened
                    }

                    FilterButton(
                        title: "Temperature",
                        icon: "thermometer",
                        isSelected: filterType == .temperatureAlert,
                        count: notificationManager.notifications.filter { $0.type == .temperatureAlert }.count
                    ) {
                        filterType = .temperatureAlert
                    }

                    FilterButton(
                        title: "Security",
                        icon: "shield.fill",
                        isSelected: filterType == .securityAlert,
                        count: notificationManager.notifications.filter { $0.type == .securityAlert }.count
                    ) {
                        filterType = .securityAlert
                    }
                }
            }

            // Action buttons
            HStack(spacing: 20) {
                Toggle("Show Unread Only", isOn: $showUnreadOnly)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                Spacer()

                Button(action: {
                    notificationManager.markAllAsRead()
                }) {
                    Label("Mark All Read", systemImage: "checkmark.circle")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: {
                    notificationManager.clearAll()
                }) {
                    Label("Clear All", systemImage: "trash")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        let todayNotifications = notificationManager.notifications.filter { Calendar.current.isDateInToday($0.timestamp) }
        let criticalNotifications = notificationManager.notifications.filter { $0.priority == .critical }

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 30) {
            StatCard(
                title: "Today",
                value: "\(todayNotifications.count)",
                icon: "calendar",
                color: .blue
            )

            StatCard(
                title: "Unread",
                value: "\(notificationManager.unreadCount)",
                icon: "bell.badge",
                color: .orange
            )

            StatCard(
                title: "Critical",
                value: "\(criticalNotifications.count)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
    }

    // MARK: - Notifications List

    private var notificationsListSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Notifications")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            let filteredNotifications = getFilteredNotifications()

            if filteredNotifications.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 15) {
                    ForEach(filteredNotifications) { notification in
                        NotificationRow(notification: notification) {
                            notificationManager.markAsRead(notification)
                        } onDelete: {
                            notificationManager.deleteNotification(notification)
                        } onTap: {
                            handleNotificationTap(notification)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rules Section

    private var rulesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Notification Rules")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                Button(action: {
                    showingRulesEditor = true
                }) {
                    Label("Manage Rules", systemImage: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(notificationManager.rules) { rule in
                    RuleCard(rule: rule) { enabled in
                        var updatedRule = rule
                        updatedRule.isEnabled = enabled
                        notificationManager.updateRule(updatedRule)
                    }
                }
            }
        }
    }

    // MARK: - Rules Editor Sheet

    private var rulesEditorSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(notificationManager.rules) { rule in
                        RuleEditorRow(rule: rule, onUpdate: { updatedRule in
                            notificationManager.updateRule(updatedRule)
                        }, onDelete: {
                            notificationManager.deleteRule(rule)
                        })
                    }

                    Button(action: {
                        // Create new rule with defaults
                        notificationManager.createRule(
                            name: "New Rule",
                            type: .custom,
                            accessoryID: nil,
                            condition: "",
                            priority: .normal,
                            cooldownSeconds: 300
                        )
                    }) {
                        Label("Add New Rule", systemImage: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 20)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                }
                .padding(40)
            }
            .navigationTitle("Manage Rules")
            .toolbar {
                Button("Done") {
                    showingRulesEditor = false
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No notifications")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
            Text("You're all caught up!")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Helper Methods

    /// Get filtered notifications based on current filters
    private func getFilteredNotifications() -> [HomeNotification] {
        var filtered = notificationManager.notifications

        // Filter by type
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }

        // Filter by read status
        if showUnreadOnly {
            filtered = filtered.filter { !$0.isRead }
        }

        return filtered
    }

    /// Handle notification tap to navigate to related accessory
    private func handleNotificationTap(_ notification: HomeNotification) {
        notificationManager.markAsRead(notification)

        // Could navigate to accessory detail view if needed
        if notification.accessoryID != nil {
            // Find and navigate to accessory
            // TODO: Implement navigation to accessory detail view
        }
    }
}

// MARK: - Supporting Views

/// Filter button for notification types
struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                if count > 0 {
                    Text("(\(count))")
                        .bold()
                }
            }
            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .padding(.horizontal, 25)
            .padding(.vertical, 15)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

/// Notification row item
struct NotificationRow: View {
    let notification: HomeNotification
    let onRead: () -> Void
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                // Icon
                Image(systemName: iconForType(notification.type))
                    .font(.title)
                    .foregroundColor(colorForPriority(notification.priority))
                    .frame(width: 60, height: 60)
                    .background(colorForPriority(notification.priority).opacity(0.2))
                    .cornerRadius(30)

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .bold()

                        if !notification.isRead {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                        }

                        Spacer()

                        Text(notification.timestamp, style: .relative)
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }

                    Text(notification.body)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    if let accessoryName = notification.accessoryName {
                        Text(accessoryName)
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.blue)
                    }
                }

                // Actions
                VStack(spacing: 10) {
                    Button(action: onRead) {
                        Image(systemName: notification.isRead ? "envelope.open.fill" : "envelope.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(notification.isRead ? Color.clear : Color.blue.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private func iconForType(_ type: NotificationType) -> String {
        switch type {
        case .accessoryOffline: return "wifi.slash"
        case .lowBattery: return "battery.25"
        case .motionDetected: return "figure.walk"
        case .doorOpened: return "door.left.hand.open"
        case .temperatureAlert: return "thermometer"
        case .leakDetected: return "drop.fill"
        case .smokeDetected: return "smoke.fill"
        case .securityAlert: return "shield.fill"
        case .automationExecuted: return "gearshape.fill"
        case .sceneExecuted: return "lightbulb.fill"
        case .custom: return "bell.fill"
        }
    }

    private func colorForPriority(_ priority: NotificationPriority) -> Color {
        switch priority {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

/// Rule card for displaying notification rules
struct RuleCard: View {
    let rule: NotificationRule
    let onToggle: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(rule.name)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                Toggle("", isOn: Binding(
                    get: { rule.isEnabled },
                    set: { onToggle($0) }
                ))
            }

            Text(rule.condition)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)

            HStack {
                priorityBadge(rule.priority)

                Spacer()

                if let lastFired = rule.lastFired {
                    Text("Last fired: \(lastFired, style: .relative) ago")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(rule.isEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func priorityBadge(_ priority: NotificationPriority) -> some View {
        Text(priority.rawValue.capitalized)
            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(colorForPriority(priority))
            .foregroundColor(.white)
            .cornerRadius(8)
    }

    private func colorForPriority(_ priority: NotificationPriority) -> Color {
        switch priority {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

/// Rule editor row for managing individual rules
struct RuleEditorRow: View {
    let rule: NotificationRule
    let onUpdate: (NotificationRule) -> Void
    let onDelete: () -> Void

    @State private var editedRule: NotificationRule

    init(rule: NotificationRule, onUpdate: @escaping (NotificationRule) -> Void, onDelete: @escaping () -> Void) {
        self.rule = rule
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self._editedRule = State(initialValue: rule)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            TextField("Rule Name", text: $editedRule.name)
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

            TextField("Condition", text: $editedRule.condition)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

            HStack {
                Toggle("Enabled", isOn: $editedRule.isEnabled)

                Spacer()

                Button("Save") {
                    onUpdate(editedRule)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Delete") {
                    onDelete()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NotificationCenterView()
        .environmentObject(HomeKitManager())
}
