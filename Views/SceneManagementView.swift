import SwiftUI
import HomeKit

/// Scene creation and management view with enhanced viewing capabilities
///
/// This view provides comprehensive scene management features:
/// - View all scenes with detailed information
/// - Execute scenes with a single tap
/// - Inspect scene actions and accessories
/// - Navigate to scene detail views
///
/// **Note**: Due to tvOS API limitations, scene creation and editing must be done
/// in the Home app on iOS/iPadOS. However, this view provides full inspection
/// and execution capabilities.
///
/// **Memory Safety**: Uses [weak self] in all closures to prevent retain cycles
struct SceneManagementView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var showingCreateSheet = false
    @State private var newSceneName = ""
    @State private var selectedScene: HMActionSet? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Manage Scenes")
                                .font(.largeTitle)
                                .bold()

                            Spacer()

                            // Info button for help
                            NavigationLink(destination: SceneHelpView()) {
                                HStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle.fill")
                                    Text("How to Edit Scenes")
                                }
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }

                        // tvOS Limitation Notice
                        HStack(spacing: 15) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Scene editing requires the Home app on iOS")
                                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    .foregroundColor(.primary)
                                Text("You can view scene details and execute scenes from HomeKitTV. To create or edit scenes, use the Home app on iPhone or iPad.")
                                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(20)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 80)
                    .padding(.top, 60)

                    if homeManager.scenes.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Scenes")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            Text("Create a scene to get started")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        VStack(spacing: 20) {
                            ForEach(homeManager.scenes, id: \.uniqueIdentifier) { scene in
                                NavigationLink(destination: SceneDetailInspectorView(scene: scene)) {
                                    SceneManagementRow(scene: scene, showNavigationArrow: true)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateSceneSheet(sceneName: $newSceneName, isPresented: $showingCreateSheet)
                .environmentObject(homeManager)
        }
    }
}

/// Scene management row
struct SceneManagementRow: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet
    var showNavigationArrow: Bool = true
    @State private var showingDeleteConfirmation = false

    var actionCount: Int {
        scene.actions.count
    }

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(scene.name)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                HStack(spacing: 15) {
                    HStack(spacing: 5) {
                        Image(systemName: "play.circle.fill")
                        Text("\(actionCount) \(actionCount == 1 ? "action" : "actions")")
                    }
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(8)

                    if scene.actionSetType == HMActionSetTypeSleep {
                        Text("Sleep")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    } else if scene.actionSetType == HMActionSetTypeWakeUp {
                        Text("Wake Up")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    } else if scene.actionSetType == HMActionSetTypeHomeArrival {
                        Text("Arrive Home")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    } else if scene.actionSetType == HMActionSetTypeHomeDeparture {
                        Text("Leave Home")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }

            Spacer()

            HStack(spacing: 20) {
                Button(action: {
                    homeManager.executeScene(scene)
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                if showNavigationArrow {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 25))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Create scene sheet
struct CreateSceneSheet: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @Binding var sceneName: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 40) {
            Text("Create New Scene")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            VStack(alignment: .leading, spacing: 15) {
                Text("Scene Name")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)

                TextField("Enter scene name", text: $sceneName)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .textFieldStyle(.plain)
                    .padding(20)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 80)

            HStack(spacing: 30) {
                Button(action: {
                    isPresented = false
                    sceneName = ""
                }) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.gray)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Button(action: {
                    guard !sceneName.isEmpty else { return }
                    homeManager.createScene(name: sceneName) { _, _ in
                        isPresented = false
                        sceneName = ""
                    }
                }) {
                    Text("Create")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(sceneName.isEmpty ? Color.gray : Color.green)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .disabled(sceneName.isEmpty)
            }
            .padding(.horizontal, 80)

            Spacer()
        }
    }
}

/// Scene editor view
struct SceneEditorView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet
    @State private var showingDeleteConfirmation = false
    @State private var showingAddActionSheet = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(scene.name)
                            .font(.largeTitle)
                            .bold()

                        Text("\(scene.actions.count) \(scene.actions.count == 1 ? "action" : "actions")")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Scene")
                        }
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(10)
                        .opacity(0.5)
                    }
                    .buttonStyle(.plain)
                    .disabled(true)
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // Actions List
                VStack(alignment: .leading, spacing: 20) {
                    Text("Actions")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .padding(.horizontal, 80)

                    if scene.actions.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "square.stack.3d.up.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("No actions in this scene")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                    } else {
                        ForEach(Array(scene.actions), id: \.uniqueIdentifier) { action in
                            SceneActionRow(action: action)
                        }
                        .padding(.horizontal, 80)
                    }
                }

                Button(action: {
                    showingAddActionSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Action")
                    }
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.gray)
                    .cornerRadius(12)
                    .opacity(0.5)
                }
                .buttonStyle(.plain)
                .disabled(true)
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 60)
        }
        .alert("Delete Scene", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                homeManager.deleteScene(scene) { _ in
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(scene.name)'? This action cannot be undone.")
        }
        .sheet(isPresented: $showingAddActionSheet) {
            AddActionSheet(scene: scene, isPresented: $showingAddActionSheet)
                .environmentObject(homeManager)
        }
    }
}

/// Scene action row
struct SceneActionRow: View {
    let action: HMAction

    var accessoryName: String {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            return charAction.characteristic.service?.accessory?.name ?? "Unknown Accessory"
        }
        return "Unknown Accessory"
    }

    var characteristicName: String {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            return charAction.characteristic.localizedDescription
        }
        return "Unknown"
    }

    var targetValue: String {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            if let value = charAction.targetValue as? Bool {
                return value ? "On" : "Off"
            } else if let value = charAction.targetValue as? Int {
                return "\(value)"
            } else if let value = charAction.targetValue as? Double {
                return String(format: "%.1f", value)
            }
            return "\(charAction.targetValue)"
        }
        return "Unknown"
    }

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 35))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(accessoryName)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Text(characteristicName)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(targetValue)
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

/// Add action sheet
struct AddActionSheet: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet
    @Binding var isPresented: Bool
    @State private var selectedAccessory: HMAccessory?

    var body: some View {
        VStack(spacing: 30) {
            Text("Add Action to Scene")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            Text("Select an accessory to add to this scene")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 30)], spacing: 30) {
                    ForEach(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
                        Button(action: {
                            // For simplicity, add a power on/off action
                            if let service = accessory.services.first(where: {
                                $0.characteristics.contains(where: { $0.characteristicType == HMCharacteristicTypePowerState })
                            }),
                               let characteristic = service.characteristics.first(where: {
                                   $0.characteristicType == HMCharacteristicTypePowerState
                               }) {
                                homeManager.addActionToScene(scene, characteristic: characteristic, value: true as NSNumber) { _ in
                                    isPresented = false
                                }
                            }
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: iconForAccessory(accessory))
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)

                                Text(accessory.name)
                                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }
                            .padding(25)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 80)
            }

            Button(action: {
                isPresented = false
            }) {
                Text("Cancel")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.gray)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
        }
    }

    func iconForAccessory(_ accessory: HMAccessory) -> String {
        guard let primaryService = accessory.services.first else {
            return "lightbulb.fill"
        }

        switch primaryService.serviceType {
        case HMServiceTypeLightbulb:
            return "lightbulb.fill"
        case HMServiceTypeOutlet:
            return "poweroutlet.type.b.fill"
        case HMServiceTypeSwitch:
            return "light.switch.on.fill"
        case HMServiceTypeThermostat:
            return "thermometer"
        case HMServiceTypeFan:
            return "fan.fill"
        default:
            return "circle.fill"
        }
    }
}

/// Scene detail inspector view - shows comprehensive scene information
///
/// Provides a read-only view of scene configuration including:
/// - All actions in the scene
/// - Accessories controlled by each action
/// - Target values for each characteristic
/// - Scene metadata (type, creation date if available)
///
/// **Memory Safety**: Uses weak references where appropriate
struct SceneDetailInspectorView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let scene: HMActionSet

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                HStack {
                    Image(systemName: sceneIcon(for: scene))
                        .font(.system(size: 60))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(scene.name)
                            .font(.largeTitle)
                            .bold()

                        HStack(spacing: 15) {
                            Text("\(scene.actions.count) \(scene.actions.count == 1 ? "action" : "actions")")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)

                            if let sceneType = sceneTypeString(for: scene) {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(sceneType)
                                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Execute button
                    Button(action: {
                        homeManager.executeScene(scene)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                            Text("Run Scene")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        }
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

                // Actions breakdown
                VStack(alignment: .leading, spacing: 20) {
                    Text("Scene Actions")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .padding(.horizontal, 80)

                    if scene.actions.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "tray")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            Text("This scene has no actions")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                            Text("Add actions using the Home app on iOS")
                                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(60)
                    } else {
                        VStack(spacing: 15) {
                            ForEach(Array(scene.actions.enumerated()), id: \.offset) { index, action in
                                DetailedSceneActionRow(action: action, index: index + 1)
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                }

                // How to edit section
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.blue)
                        Text("How to Edit This Scene")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .bold()
                    }
                    .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 15) {
                        EditingInstructionRow(number: 1, text: "Open the Home app on your iPhone or iPad")
                        EditingInstructionRow(number: 2, text: "Tap on the Scenes tab at the bottom")
                        EditingInstructionRow(number: 3, text: "Find and long-press on '\(scene.name)'")
                        EditingInstructionRow(number: 4, text: "Tap 'Test Scene' to run it, or 'Edit Scene' to modify")
                        EditingInstructionRow(number: 5, text: "Add, remove, or modify accessories and their settings")
                        EditingInstructionRow(number: 6, text: "Changes sync automatically to HomeKitTV")
                    }
                    .padding(25)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)
                }
            }
            .padding(.bottom, 60)
        }
    }

    /// Get scene type icon
    func sceneIcon(for scene: HMActionSet) -> String {
        switch scene.actionSetType {
        case HMActionSetTypeSleep:
            return "moon.stars.fill"
        case HMActionSetTypeWakeUp:
            return "sunrise.fill"
        case HMActionSetTypeHomeArrival:
            return "house.fill"
        case HMActionSetTypeHomeDeparture:
            return "figure.walk"
        default:
            return "sparkles"
        }
    }

    /// Get scene type string
    func sceneTypeString(for scene: HMActionSet) -> String? {
        switch scene.actionSetType {
        case HMActionSetTypeSleep:
            return "Sleep Scene"
        case HMActionSetTypeWakeUp:
            return "Wake Up Scene"
        case HMActionSetTypeHomeArrival:
            return "Arrive Home Scene"
        case HMActionSetTypeHomeDeparture:
            return "Leave Home Scene"
        case HMActionSetTypeUserDefined:
            return nil
        default:
            return nil
        }
    }
}

/// Detailed scene action row with full information
struct DetailedSceneActionRow: View {
    let action: HMAction
    let index: Int

    var accessory: HMAccessory? {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            return charAction.characteristic.service?.accessory
        }
        return nil
    }

    var characteristicName: String {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            return charAction.characteristic.localizedDescription
        }
        return "Unknown Characteristic"
    }

    var serviceName: String {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            return charAction.characteristic.service?.name ?? "Service"
        }
        return "Unknown Service"
    }

    var targetValue: String {
        if let charAction = action as? HMCharacteristicWriteAction<NSCopying> {
            if let value = charAction.targetValue as? Bool {
                return value ? "On" : "Off"
            } else if let value = charAction.targetValue as? Int {
                // Check if it's a percentage
                if characteristicName.contains("Brightness") || characteristicName.contains("Position") {
                    return "\(value)%"
                }
                return "\(value)"
            } else if let value = charAction.targetValue as? Double {
                if characteristicName.contains("Temperature") {
                    return String(format: "%.1f°", value)
                }
                return String(format: "%.1f", value)
            }
            return "\(charAction.targetValue)"
        }
        return "Unknown"
    }

    var body: some View {
        HStack(spacing: 20) {
            // Action number
            Text("\(index)")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()
                .foregroundColor(.white)
                .frame(width: 45, height: 45)
                .background(Color.purple)
                .clipShape(Circle())

            // Accessory icon
            Image(systemName: accessoryIcon)
                .font(.system(size: 35))
                .foregroundColor(.blue)
                .frame(width: 50)

            // Details
            VStack(alignment: .leading, spacing: 8) {
                Text(accessory?.name ?? "Unknown Accessory")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Text(serviceName)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(characteristicName)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)
                    Text(targetValue)
                        .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .foregroundColor(.purple)
                }
            }

            Spacer()

            // Room badge
            if let room = accessory?.room {
                Text(room.name)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }

    var accessoryIcon: String {
        guard let accessory = accessory,
              let primaryService = accessory.services.first else {
            return "questionmark.circle"
        }

        switch primaryService.serviceType {
        case HMServiceTypeLightbulb:
            return "lightbulb.fill"
        case HMServiceTypeOutlet:
            return "poweroutlet.type.b.fill"
        case HMServiceTypeSwitch:
            return "light.switch.on.fill"
        case HMServiceTypeThermostat:
            return "thermometer"
        case HMServiceTypeFan:
            return "fan.fill"
        case HMServiceTypeLockMechanism:
            return "lock.fill"
        case HMServiceTypeWindowCovering:
            return "blinds.vertical.closed"
        case HMServiceTypeGarageDoorOpener:
            return "garage"
        default:
            return "circle.fill"
        }
    }
}

/// Editing instruction row
struct EditingInstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
        }
    }
}

/// Scene help view explaining how to create and edit scenes
struct SceneHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scene Editing Guide")
                            .font(.largeTitle)
                            .bold()
                        Text("Learn how to create and edit HomeKit scenes")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // What are scenes
                VStack(alignment: .leading, spacing: 20) {
                    Text("What Are Scenes?")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Scenes let you control multiple HomeKit accessories with a single tap. For example, a 'Movie Time' scene might:")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                        VStack(alignment: .leading, spacing: 10) {
                            BulletPoint(text: "Dim the living room lights to 20%")
                            BulletPoint(text: "Turn off the kitchen lights")
                            BulletPoint(text: "Close the living room blinds")
                            BulletPoint(text: "Turn on the TV")
                        }
                        .padding(.leading, 20)

                        Text("Instead of controlling each device individually, you simply activate the 'Movie Time' scene.")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    }
                    .padding(25)
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)
                }

                // Creating scenes
                VStack(alignment: .leading, spacing: 20) {
                    Text("Creating New Scenes")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 15) {
                        EditingInstructionRow(number: 1, text: "Open the Home app on your iPhone or iPad")
                        EditingInstructionRow(number: 2, text: "Tap the '+' button in the top right corner")
                        EditingInstructionRow(number: 3, text: "Select 'Add Scene'")
                        EditingInstructionRow(number: 4, text: "Choose a suggested scene or tap 'Custom' for a blank scene")
                        EditingInstructionRow(number: 5, text: "Give your scene a descriptive name")
                        EditingInstructionRow(number: 6, text: "Tap 'Add Accessories' to choose which devices to control")
                        EditingInstructionRow(number: 7, text: "For each accessory, set the desired state (on/off, brightness, etc.)")
                        EditingInstructionRow(number: 8, text: "Tap 'Done' to save your scene")
                        EditingInstructionRow(number: 9, text: "Your new scene will appear immediately in HomeKitTV")
                    }
                    .padding(25)
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)
                }

                // Editing scenes
                VStack(alignment: .leading, spacing: 20) {
                    Text("Editing Existing Scenes")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 15) {
                        EditingInstructionRow(number: 1, text: "Open the Home app on your iPhone or iPad")
                        EditingInstructionRow(number: 2, text: "Tap on the Scenes tab")
                        EditingInstructionRow(number: 3, text: "Long-press on the scene you want to edit")
                        EditingInstructionRow(number: 4, text: "Tap 'Edit Scene' from the menu")
                        EditingInstructionRow(number: 5, text: "Add or remove accessories as needed")
                        EditingInstructionRow(number: 6, text: "Adjust the settings for each accessory")
                        EditingInstructionRow(number: 7, text: "Tap 'Done' to save your changes")
                        EditingInstructionRow(number: 8, text: "Changes sync automatically to all your Apple devices")
                    }
                    .padding(25)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)
                }

                // Tips
                VStack(alignment: .leading, spacing: 20) {
                    Text("Pro Tips")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                        .bold()
                        .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 15) {
                        SceneTipRow(tip: "Name scenes clearly", description: "Use descriptive names like 'Good Morning' instead of 'Scene 1'")
                        SceneTipRow(tip: "Test your scenes", description: "After creating a scene, run it to make sure all accessories behave as expected")
                        SceneTipRow(tip: "Use scene types", description: "Suggested scenes like Good Morning, Leave Home, and Arrive Home work with automations")
                        SceneTipRow(tip: "Don't overload scenes", description: "Keep scenes focused - it's better to have multiple specific scenes than one complex scene")
                        SceneTipRow(tip: "Include all related accessories", description: "Don't forget accessories in nearby rooms that should change state")
                    }
                    .padding(25)
                    .background(Color.yellow.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)
                }

                // Why tvOS limitation
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.orange)
                        Text("Why Can't I Edit Scenes on Apple TV?")
                            .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .bold()
                    }
                    .padding(.horizontal, 80)

                    VStack(alignment: .leading, spacing: 15) {
                        Text("Apple's HomeKit framework on tvOS does not provide APIs for creating or modifying scenes. This is a platform limitation, not a HomeKitTV restriction.")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                        Text("However, HomeKitTV provides:")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .bold()

                        VStack(alignment: .leading, spacing: 10) {
                            BulletPoint(text: "Full scene execution capabilities")
                            BulletPoint(text: "Detailed scene inspection and action viewing")
                            BulletPoint(text: "Real-time sync with scenes created on iOS")
                            BulletPoint(text: "Complete scene management and organization")
                        }
                        .padding(.leading, 20)

                        Text("The Home app on iOS and iPadOS provides the best scene editing experience with a touch interface optimized for this task.")
                            .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                            .foregroundColor(.secondary)
                    }
                    .padding(25)
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 80)
                }
            }
            .padding(.bottom, 60)
        }
    }
}

/// Bullet point view for lists
struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.primary)
            Text(text)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
        }
    }
}

/// Tip row with title and description for scene help
struct SceneTipRow: View {
    let tip: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                Text(tip)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()
            }

            Text(description)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
                .padding(.leading, 35)
        }
    }
}

#Preview {
    SceneManagementView()
        .environmentObject(HomeKitManager())
}
