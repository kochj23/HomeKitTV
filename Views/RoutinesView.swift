import SwiftUI
import HomeKit

/// Routines Management View
///
/// Comprehensive interface for managing smart home routines:
/// - Create/edit/delete routines
/// - Condition-based automation ("If temp > 75°F, turn on fan")
/// - Time-based sequences with delays
/// - Multi-step routines with sequential actions
/// - Enable/disable routines
/// - Trigger configuration (manual, time, location, etc.)
///
/// **Backend Integration**: Uses RoutineManager.shared
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Uses @ObservedObject to prevent retain cycles
///
/// **Features**:
/// - Visual routine builder
/// - Action sequencing with delays
/// - Condition editor
/// - Schedule configuration
/// - Execution progress tracking
///
/// - SeeAlso: `RoutineManager`, `Routine`, `RoutineAction`
struct RoutinesView: View {
    @ObservedObject private var routineManager = RoutineManager.shared
    @EnvironmentObject var homeManager: HomeKitManager

    @State private var showingEditor = false
    @State private var editingRoutine: Routine?
    @State private var showingExecutionProgress = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                headerSection

                // Statistics
                statisticsSection

                // Active Routines
                activeRoutinesSection

                // All Routines
                allRoutinesSection
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
        .sheet(isPresented: $showingEditor) {
            routineEditorSheet
        }
        .overlay {
            if showingExecutionProgress, let executing = routineManager.executingRoutine {
                executionProgressOverlay(executing)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Routines")
                    .font(.largeTitle)
                    .bold()
                Text("Automate your home with multi-step routines")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                editingRoutine = nil
                showingEditor = true
            }) {
                Label("New Routine", systemImage: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        let enabled = routineManager.routines.filter { $0.isEnabled }.count
        let automated = routineManager.routines.filter { $0.trigger != .manual }.count

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 30) {
            StatCard(
                title: "Total Routines",
                value: "\(routineManager.routines.count)",
                icon: "sparkles",
                color: .purple
            )

            StatCard(
                title: "Enabled",
                value: "\(enabled)",
                icon: "checkmark.circle.fill",
                color: .green
            )

            StatCard(
                title: "Automated",
                value: "\(automated)",
                icon: "gearshape.2.fill",
                color: .blue
            )
        }
    }

    // MARK: - Active Routines Section

    private var activeRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Access")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            let activeRoutines = routineManager.routines.filter { $0.isEnabled }.prefix(4)

            if activeRoutines.isEmpty {
                Text("No active routines")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(Array(activeRoutines)) { routine in
                        QuickRoutineCard(routine: routine) {
                            executeRoutine(routine)
                        } onEdit: {
                            editingRoutine = routine
                            showingEditor = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - All Routines Section

    private var allRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("All Routines")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            if routineManager.routines.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 15) {
                    ForEach(routineManager.routines) { routine in
                        RoutineRow(routine: routine,
                                   onExecute: {
                            executeRoutine(routine)
                        }, onEdit: {
                            editingRoutine = routine
                            showingEditor = true
                        }, onToggle: { enabled in
                            var updated = routine
                            updated.isEnabled = enabled
                            routineManager.updateRoutine(updated)
                        }, onDelete: {
                            routineManager.deleteRoutine(routine)
                        })
                    }
                }
            }
        }
    }

    // MARK: - Routine Editor Sheet

    private var routineEditorSheet: some View {
        RoutineEditorView(routine: editingRoutine, isPresented: $showingEditor)
            .environmentObject(homeManager)
    }

    // MARK: - Execution Progress Overlay

    private func executionProgressOverlay(_ routine: Routine) -> some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: routine.iconName)
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("Executing \(routine.name)")
                    .font(.title)
                    .bold()
                    .foregroundColor(.white)

                ProgressView(value: routineManager.executionProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 600)
                    .scaleEffect(y: 2.0)

                Text("\(Int(routineManager.executionProgress * 100))%")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
            }
            .padding(60)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(20)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No routines yet")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
            Text("Create your first routine to automate multiple actions")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Helper Methods

    private func executeRoutine(_ routine: Routine) {
        showingExecutionProgress = true
        routineManager.executeRoutine(routine, homeManager: homeManager) { success, error in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showingExecutionProgress = false
            }

            if !success {
                homeManager.statusMessage = "Routine failed: \(error?.localizedDescription ?? "Unknown error")"
            } else {
                homeManager.statusMessage = "Routine '\(routine.name)' executed successfully"
            }
        }
    }
}

// MARK: - Quick Routine Card

struct QuickRoutineCard: View {
    let routine: Routine
    let onExecute: () -> Void
    let onEdit: () -> Void

    var body: some View {
        Button(action: onExecute) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: routine.iconName)
                        .font(.title)
                        .foregroundColor(colorForRoutine)

                    Spacer()

                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }

                Text(routine.name)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                if !routine.description.isEmpty {
                    Text(routine.description)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    triggerBadge

                    Spacer()

                    Text("\(routine.actions.count) actions")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }
            }
            .padding(25)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(colorForRoutine.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var colorForRoutine: Color {
        switch routine.colorName {
        case "yellow": return .yellow
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "indigo": return .indigo
        case "red": return .red
        default: return .blue
        }
    }

    private var triggerBadge: some View {
        Text(routine.trigger.rawValue.capitalized)
            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
    }
}

// MARK: - Routine Row

struct RoutineRow: View {
    let routine: Routine
    let onExecute: () -> Void
    let onEdit: () -> Void
    let onToggle: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Icon
            Image(systemName: routine.iconName)
                .font(.title)
                .foregroundColor(colorForRoutine)
                .frame(width: 60, height: 60)
                .background(colorForRoutine.opacity(0.2))
                .cornerRadius(30)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(routine.name)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                if !routine.description.isEmpty {
                    Text(routine.description)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }

                HStack {
                    triggerBadge

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(routine.actions.count) actions")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)

                    if let lastExecuted = routine.lastExecuted {
                        Text("•")
                            .foregroundColor(.secondary)

                        Text("Last: \(lastExecuted, style: .relative) ago")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("Runs: \(routine.executionCount)")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 15) {
                Toggle("", isOn: Binding(
                    get: { routine.isEnabled },
                    set: { onToggle($0) }
                ))

                Button(action: onExecute) {
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var colorForRoutine: Color {
        switch routine.colorName {
        case "yellow": return .yellow
        case "orange": return .orange
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "indigo": return .indigo
        case "red": return .red
        default: return .blue
        }
    }

    private var triggerBadge: some View {
        Text(routine.trigger.rawValue.capitalized)
            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)
    }
}

// MARK: - Routine Editor View

struct RoutineEditorView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var routineManager = RoutineManager.shared

    let routine: Routine?
    @Binding var isPresented: Bool

    @State private var name: String
    @State private var description: String
    @State private var iconName: String
    @State private var colorName: String
    @State private var trigger: RoutineTrigger
    @State private var triggerTime: Date
    @State private var actions: [RoutineAction]
    @State private var isEnabled: Bool

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    init(routine: Routine?, isPresented: Binding<Bool>) {
        self.routine = routine
        self._isPresented = isPresented

        if let routine = routine {
            self._name = State(initialValue: routine.name)
            self._description = State(initialValue: routine.description)
            self._iconName = State(initialValue: routine.iconName)
            self._colorName = State(initialValue: routine.colorName)
            self._trigger = State(initialValue: routine.trigger)
            self._triggerTime = State(initialValue: routine.triggerTime ?? Date())
            self._actions = State(initialValue: routine.actions)
            self._isEnabled = State(initialValue: routine.isEnabled)
        } else {
            self._name = State(initialValue: "New Routine")
            self._description = State(initialValue: "")
            self._iconName = State(initialValue: "sparkles")
            self._colorName = State(initialValue: "purple")
            self._trigger = State(initialValue: .manual)
            self._triggerTime = State(initialValue: Date())
            self._actions = State(initialValue: [])
            self._isEnabled = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Basic Info
                    basicInfoSection

                    // Trigger Configuration
                    triggerSection

                    // Actions
                    actionsSection

                    // Save/Cancel Buttons
                    buttonsSection
                }
                .padding(40)
            }
            .navigationTitle(routine == nil ? "New Routine" : "Edit Routine")
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Basic Information")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            TextField("Routine Name", text: $name)
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .textFieldStyle(.plain)
                .padding(15)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            TextField("Description (optional)", text: $description)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .textFieldStyle(.plain)
                .padding(15)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            HStack {
                Text("Icon:")
                Picker("Icon", selection: $iconName) {
                    Text("✨ Sparkles").tag("sparkles")
                    Text("☀️ Sun").tag("sun.max.fill")
                    Text("🌙 Moon").tag("moon.stars.fill")
                    Text("🏠 House").tag("house.fill")
                    Text("🎬 Film").tag("film.fill")
                    Text("🔒 Lock").tag("lock.fill")
                    Text("💡 Lightbulb").tag("lightbulb.fill")
                }
                .frame(width: 300)
            }

            HStack {
                Text("Color:")
                Picker("Color", selection: $colorName) {
                    Text("Blue").tag("blue")
                    Text("Green").tag("green")
                    Text("Purple").tag("purple")
                    Text("Orange").tag("orange")
                    Text("Red").tag("red")
                    Text("Yellow").tag("yellow")
                    Text("Indigo").tag("indigo")
                }
                .frame(width: 300)
            }

            Toggle("Enabled", isOn: $isEnabled)
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Trigger")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            Picker("Trigger Type", selection: $trigger) {
                Text("Manual Only").tag(RoutineTrigger.manual)
                Text("Time of Day").tag(RoutineTrigger.timeOfDay)
                Text("Sunrise").tag(RoutineTrigger.sunrise)
                Text("Sunset").tag(RoutineTrigger.sunset)
                Text("Arrive Home").tag(RoutineTrigger.arriveHome)
                Text("Leave Home").tag(RoutineTrigger.leaveHome)
            }
            .pickerStyle(.segmented)

            if trigger == .timeOfDay {
                #if os(iOS) || os(watchOS)
                DatePicker("Time", selection: $triggerTime, displayedComponents: .hourAndMinute)
                #else
                Text("Time: \(triggerTime, formatter: Self.timeFormatter)")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                #endif
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Actions (\(actions.count))")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                if #available(tvOS 17.0, *) {
                    Menu {
                        Button("Execute Scene") {
                            addSceneAction()
                        }

                        Button("Wait/Delay") {
                            addWaitAction()
                        }
                    } label: {
                        Label("Add Action", systemImage: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: addSceneAction) {
                        Label("Add Action", systemImage: "plus.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 25)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }

            if actions.isEmpty {
                Text("No actions yet. Add actions to build your routine.")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .padding(30)
            } else {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                    ActionRow(action: action, index: index + 1) {
                        actions.removeAll { $0.id == action.id }
                    }
                }
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var buttonsSection: some View {
        HStack(spacing: 20) {
            Button("Cancel") {
                isPresented = false
            }
            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Color.gray.opacity(0.3))
            .foregroundColor(.primary)
            .cornerRadius(12)

            Spacer()

            Button("Save Routine") {
                saveRoutine()
            }
            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Helper Methods

    private func addSceneAction() {
        let action = RoutineAction(
            type: .executeScene,
            targetID: homeManager.scenes.first?.uniqueIdentifier,
            order: actions.count
        )
        actions.append(action)
    }

    private func addWaitAction() {
        let action = RoutineAction(
            type: .wait,
            waitDuration: 5.0,
            order: actions.count
        )
        actions.append(action)
    }

    private func saveRoutine() {
        if let existing = routine {
            var updated = existing
            updated.name = name
            updated.description = description
            updated.iconName = iconName
            updated.colorName = colorName
            updated.trigger = trigger
            updated.triggerTime = trigger == .timeOfDay ? triggerTime : nil
            updated.actions = actions
            updated.isEnabled = isEnabled
            routineManager.updateRoutine(updated)
        } else {
            var newRoutine = Routine(
                name: name,
                description: description,
                iconName: iconName,
                colorName: colorName,
                actions: actions,
                trigger: trigger
            )
            newRoutine.triggerTime = trigger == .timeOfDay ? triggerTime : nil
            newRoutine.isEnabled = isEnabled
            _ = routineManager.createRoutine(
                name: newRoutine.name,
                description: newRoutine.description,
                iconName: newRoutine.iconName,
                colorName: newRoutine.colorName,
                trigger: newRoutine.trigger
            )
        }

        isPresented = false
    }
}

// MARK: - Action Row

struct ActionRow: View {
    let action: RoutineAction
    let index: Int
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("\(index)")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 5) {
                Text(action.type.rawValue.capitalized)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                if action.type == .wait {
                    Text("Duration: \(Int(action.waitDuration))s")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(15)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    RoutinesView()
        .environmentObject(HomeKitManager())
}
