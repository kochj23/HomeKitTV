import SwiftUI
import UniformTypeIdentifiers

/// Backup and export management view
struct BackupView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var backupManager = BackupManager.shared
    @State private var showingCreateBackup = false
    @State private var showingExportSuccess = false
    @State private var exportedURL: URL?
    @State private var backupName = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Backup & Export")
                                .font(.largeTitle)
                                .bold()

                            if let lastBackup = backupManager.lastBackupDate {
                                Text("Last backup: \(lastBackup.formatted())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        Button(action: {
                            showingCreateBackup = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                Text("Create Backup")
                            }
                            .font(.title3)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick Actions")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 450), spacing: 30)], spacing: 30) {
                            QuickBackupCard(
                                title: "Export Scenes",
                                icon: "sparkles",
                                description: "Export all scenes as JSON",
                                color: .purple
                            ) {
                                exportScenes()
                            }

                            QuickBackupCard(
                                title: "Export Automations",
                                icon: "gearshape.2.fill",
                                description: "Export all automations",
                                color: .orange
                            ) {
                                exportAutomations()
                            }

                            QuickBackupCard(
                                title: "Export Settings",
                                icon: "gearshape.fill",
                                description: "Export app preferences",
                                color: .blue
                            ) {
                                exportSettings()
                            }

                            QuickBackupCard(
                                title: "Full Backup",
                                icon: "externaldrive.fill",
                                description: "Complete configuration backup",
                                color: .green
                            ) {
                                createQuickBackup()
                            }
                        }
                        .padding(.horizontal, 80)
                    }

                    // Backup History
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Backup History")
                            .font(.title2)
                            .padding(.horizontal, 80)

                        if backupManager.backups.isEmpty {
                            VStack(spacing: 25) {
                                Image(systemName: "archivebox")
                                    .font(.system(size: 70))
                                    .foregroundColor(.secondary)
                                Text("No Backups Yet")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(80)
                        } else {
                            ForEach(backupManager.backups) { backup in
                                NavigationLink(destination: BackupDetailView(backup: backup)) {
                                    BackupRow(backup: backup)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingCreateBackup) {
            CreateBackupSheet(backupName: $backupName, isPresented: $showingCreateBackup)
                .environmentObject(homeManager)
        }
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            if let url = exportedURL {
                Text("Backup exported to:\n\(url.path)")
            }
        }
    }

    private func exportScenes() {
        let backup = backupManager.createBackup(homeManager: homeManager, name: "Scenes Export")
        if let url = backupManager.exportToJSON(backup) {
            exportedURL = url
            showingExportSuccess = true
        }
    }

    private func exportAutomations() {
        let backup = backupManager.createBackup(homeManager: homeManager, name: "Automations Export")
        if let url = backupManager.exportToJSON(backup) {
            exportedURL = url
            showingExportSuccess = true
        }
    }

    private func exportSettings() {
        let backup = backupManager.createBackup(homeManager: homeManager, name: "Settings Export")
        if let url = backupManager.exportToJSON(backup) {
            exportedURL = url
            showingExportSuccess = true
        }
    }

    private func createQuickBackup() {
        let backup = backupManager.createBackup(homeManager: homeManager)
        if let url = backupManager.exportToJSON(backup) {
            exportedURL = url
            showingExportSuccess = true
        }
    }
}

/// Quick backup action card
struct QuickBackupCard: View {
    let title: String
    let icon: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 45))
                    .foregroundColor(color)

                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(25)
            .background(color.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
    }
}

/// Backup row in list
struct BackupRow: View {
    let backup: HomeBackup

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: "archivebox.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(backup.name)
                    .font(.title3)
                    .bold()

                HStack(spacing: 15) {
                    Label("\(backup.scenes.count) scenes", systemImage: "sparkles")
                    Label("\(backup.automations.count) automations", systemImage: "gearshape.2")
                }
                .font(.caption)
                .foregroundColor(.secondary)

                Text(backup.timestamp.formatted())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 25))
                .foregroundColor(.secondary)
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Backup detail view
struct BackupDetailView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var backupManager = BackupManager.shared
    let backup: HomeBackup
    @State private var showingDeleteConfirmation = false
    @State private var showingRestoreConfirmation = false
    @State private var showingExportSuccess = false
    @State private var exportedURL: URL?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(backup.name)
                        .font(.largeTitle)
                        .bold()

                    Text(backup.homeName)
                        .font(.title3)
                        .foregroundColor(.secondary)

                    Text("Created: \(backup.timestamp.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // Actions
                VStack(spacing: 20) {
                    Button(action: {
                        if let url = backupManager.exportToJSON(backup) {
                            exportedURL = url
                            showingExportSuccess = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export to JSON")
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showingRestoreConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restore Backup")
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Backup")
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 80)

                // Content Summary
                VStack(alignment: .leading, spacing: 30) {
                    // Scenes
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Scenes (\(backup.scenes.count))")
                        }
                        .font(.title2)

                        ForEach(backup.scenes.prefix(5), id: \.name) { scene in
                            HStack {
                                Text(scene.name)
                                    .font(.title3)
                                Spacer()
                                Text("\(scene.actions.count) actions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }

                        if backup.scenes.count > 5 {
                            Text("+ \(backup.scenes.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Automations
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "gearshape.2.fill")
                            Text("Automations (\(backup.automations.count))")
                        }
                        .font(.title2)

                        ForEach(backup.automations.prefix(5), id: \.name) { automation in
                            HStack {
                                Text(automation.name)
                                    .font(.title3)
                                Spacer()
                                Text(automation.triggerType)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }

                        if backup.automations.count > 5 {
                            Text("+ \(backup.automations.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Service Groups
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "square.stack.3d.up.fill")
                            Text("Service Groups (\(backup.serviceGroups.count))")
                        }
                        .font(.title2)

                        ForEach(backup.serviceGroups.prefix(5)) { group in
                            HStack {
                                Image(systemName: group.icon)
                                    .foregroundColor(colorForName(group.color))
                                Text(group.name)
                                    .font(.title3)
                                Spacer()
                                Text("\(group.accessoryIDs.count) accessories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(15)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(10)
                        }

                        if backup.serviceGroups.count > 5 {
                            Text("+ \(backup.serviceGroups.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 60)
            }
        }
        .alert("Delete Backup", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                backupManager.deleteBackup(backup)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this backup?")
        }
        .alert("Restore Backup", isPresented: $showingRestoreConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restore", role: .destructive) {
                backupManager.restoreBackup(backup, homeManager: homeManager) { success in
                    if success {
                        homeManager.statusMessage = "Backup restored successfully"
                    }
                }
            }
        } message: {
            Text("This will restore settings from this backup. Scenes and automations cannot be automatically restored.")
        }
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            if let url = exportedURL {
                Text("Backup exported to:\n\(url.path)")
            }
        }
    }

    func colorForName(_ name: String) -> Color {
        switch name {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

/// Create backup sheet
struct CreateBackupSheet: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var backupManager = BackupManager.shared
    @Binding var backupName: String
    @Binding var isPresented: Bool
    @State private var exportAfterCreate = true

    var body: some View {
        VStack(spacing: 40) {
            Text("Create Backup")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            VStack(alignment: .leading, spacing: 15) {
                Text("Backup Name")
                    .font(.title3)

                TextField("Enter backup name", text: $backupName)
                    .font(.title3)
                    .textFieldStyle(.plain)
                    .padding(20)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 80)

            Toggle(isOn: $exportAfterCreate) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export to JSON file after creating")
                        .font(.title3)
                }
            }
            .padding(25)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal, 80)

            // Preview
            VStack(alignment: .leading, spacing: 15) {
                Text("Backup will include:")
                    .font(.title3)
                    .foregroundColor(.secondary)

                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("\(homeManager.scenes.count) scenes")
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "gearshape.2.fill")
                        Text("\(homeManager.triggers.count) automations")
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "star.fill")
                        Text("\(Settings.shared.favoriteAccessoryIDs.count) favorite accessories")
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill")
                        Text("\(ServiceGroupManager.shared.serviceGroups.count) service groups")
                        Spacer()
                    }
                }
                .font(.title3)
            }
            .padding(25)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal, 80)

            Spacer()

            HStack(spacing: 30) {
                Button("Cancel") {
                    isPresented = false
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)

                Button("Create") {
                    let backup = backupManager.createBackup(homeManager: homeManager, name: backupName.isEmpty ? nil : backupName)
                    if exportAfterCreate {
                        _ = backupManager.exportToJSON(backup)
                    }
                    isPresented = false
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    BackupView()
        .environmentObject(HomeKitManager())
}
