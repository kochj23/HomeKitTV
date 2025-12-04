import SwiftUI
import HomeKit

/// Service groups management view
struct ServiceGroupsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var groupManager = ServiceGroupManager.shared
    @State private var showingCreateSheet = false
    @State private var showingSuggestions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    HStack {
                        Text("Service Groups")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        HStack(spacing: 20) {
                            Button(action: {
                                showingSuggestions = true
                            }) {
                                HStack {
                                    Image(systemName: "sparkles")
                                    Text("Suggestions")
                                }
                                .font(.title3)
                                .padding(.horizontal, 25)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                showingCreateSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("New Group")
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

                    if groupManager.serviceGroups.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Service Groups")
                                .font(.title2)
                            Text("Create groups to organize accessories")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 550), spacing: 40)], spacing: 40) {
                            ForEach(groupManager.serviceGroups) { group in
                                NavigationLink(destination: ServiceGroupDetailView(group: group)) {
                                    ServiceGroupCard(group: group)
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
            ServiceGroupEditorView(group: nil, isPresented: $showingCreateSheet)
                .environmentObject(homeManager)
        }
        .sheet(isPresented: $showingSuggestions) {
            SmartGroupSuggestionsView(isPresented: $showingSuggestions)
                .environmentObject(homeManager)
        }
    }
}

/// Service group card
struct ServiceGroupCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var groupManager = ServiceGroupManager.shared
    let group: ServiceGroup

    var accessories: [HMAccessory] {
        groupManager.accessories(for: group, from: homeManager)
    }

    var activeCount: Int {
        accessories.filter { homeManager.getPowerState($0) }.count
    }

    var colorForGroup: Color {
        switch group.color {
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

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: group.icon)
                .font(.system(size: 50))
                .foregroundColor(colorForGroup)
                .frame(width: 70)

            VStack(alignment: .leading, spacing: 8) {
                Text(group.name)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)

                HStack(spacing: 15) {
                    Text("\(accessories.count) accessories")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if activeCount > 0 {
                        Text("\(activeCount) on")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(colorForGroup.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Service group detail view
struct ServiceGroupDetailView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var groupManager = ServiceGroupManager.shared
    let group: ServiceGroup

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) var dismiss

    var accessories: [HMAccessory] {
        groupManager.accessories(for: group, from: homeManager)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.name)
                            .font(.largeTitle)
                            .bold()

                        Text("\(accessories.count) accessories")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 20) {
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                // Group Actions
                VStack(alignment: .leading, spacing: 20) {
                    Text("Group Actions")
                        .font(.title2)
                        .padding(.horizontal, 80)

                    HStack(spacing: 25) {
                        Button(action: {
                            groupManager.turnOnAll(group: group, homeManager: homeManager)
                        }) {
                            HStack {
                                Image(systemName: "power.circle.fill")
                                Text("Turn All On")
                            }
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            groupManager.turnOffAll(group: group, homeManager: homeManager)
                        }) {
                            HStack {
                                Image(systemName: "power.circle")
                                Text("Turn All Off")
                            }
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 80)
                }

                // Accessories in Group
                VStack(alignment: .leading, spacing: 20) {
                    Text("Accessories")
                        .font(.title2)
                        .padding(.horizontal, 80)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 400), spacing: 40)], spacing: 40) {
                        ForEach(accessories, id: \.uniqueIdentifier) { accessory in
                            AccessoryCard(accessory: accessory)
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showingEditSheet) {
            ServiceGroupEditorView(group: group, isPresented: $showingEditSheet)
                .environmentObject(homeManager)
        }
        .alert("Delete Group", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                groupManager.deleteGroup(group)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(group.name)'?")
        }
    }
}

/// Service group editor
struct ServiceGroupEditorView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var groupManager = ServiceGroupManager.shared
    let group: ServiceGroup?
    @Binding var isPresented: Bool

    @State private var name: String
    @State private var icon: String
    @State private var color: String
    @State private var selectedAccessories: Set<String>

    let icons = ["lightbulb.fill", "fan.fill", "lock.fill", "thermometer", "poweroutlet.type.b.fill", "light.switch.on.fill", "building.2.fill", "sun.max.fill", "moon.stars.fill"]
    let colors = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "cyan"]

    init(group: ServiceGroup?, isPresented: Binding<Bool>) {
        self.group = group
        self._isPresented = isPresented

        if let group = group {
            _name = State(initialValue: group.name)
            _icon = State(initialValue: group.icon)
            _color = State(initialValue: group.color)
            _selectedAccessories = State(initialValue: group.accessoryIDs)
        } else {
            _name = State(initialValue: "")
            _icon = State(initialValue: "lightbulb.fill")
            _color = State(initialValue: "blue")
            _selectedAccessories = State(initialValue: [])
        }
    }

    var body: some View {
        VStack(spacing: 30) {
            Text(group == nil ? "Create Service Group" : "Edit Service Group")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            // Name
            TextField("Group Name", text: $name)
                .font(.title3)
                .textFieldStyle(.plain)
                .padding(20)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 80)

            // Icon Selection
            VStack(alignment: .leading, spacing: 15) {
                Text("Icon")
                    .font(.title3)

                HStack(spacing: 15) {
                    ForEach(icons, id: \.self) { iconName in
                        Button(action: {
                            icon = iconName
                        }) {
                            Image(systemName: iconName)
                                .font(.system(size: 30))
                                .foregroundColor(icon == iconName ? .white : .primary)
                                .frame(width: 60, height: 60)
                                .background(icon == iconName ? Color.blue : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 80)

            // Color Selection
            VStack(alignment: .leading, spacing: 15) {
                Text("Color")
                    .font(.title3)

                HStack(spacing: 15) {
                    ForEach(colors, id: \.self) { colorName in
                        Button(action: {
                            color = colorName
                        }) {
                            Circle()
                                .fill(colorForName(colorName))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: color == colorName ? 5 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 80)

            // Accessory Selection
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Select Accessories (\(selectedAccessories.count) selected)")
                        .font(.title3)

                    ForEach(homeManager.accessories, id: \.uniqueIdentifier) { accessory in
                        Button(action: {
                            let id = accessory.uniqueIdentifier.uuidString
                            if selectedAccessories.contains(id) {
                                selectedAccessories.remove(id)
                            } else {
                                selectedAccessories.insert(id)
                            }
                        }) {
                            HStack {
                                Image(systemName: selectedAccessories.contains(accessory.uniqueIdentifier.uuidString) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 25))
                                    .foregroundColor(.blue)

                                Text(accessory.name)
                                    .font(.title3)

                                Spacer()

                                Text(accessory.room?.name ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(20)
                            .background(selectedAccessories.contains(accessory.uniqueIdentifier.uuidString) ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 80)
            }

            // Buttons
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

                Button(group == nil ? "Create" : "Save") {
                    if let existingGroup = group {
                        groupManager.updateGroup(existingGroup, name: name, icon: icon, color: color, accessoryIDs: selectedAccessories)
                    } else {
                        groupManager.createGroup(name: name, icon: icon, color: color, accessoryIDs: selectedAccessories)
                    }
                    isPresented = false
                }
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(name.isEmpty || selectedAccessories.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .buttonStyle(.plain)
                .disabled(name.isEmpty || selectedAccessories.isEmpty)
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 40)
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

/// Smart group suggestions view
struct SmartGroupSuggestionsView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var groupManager = ServiceGroupManager.shared
    @Binding var isPresented: Bool

    var suggestions: [ServiceGroup] {
        groupManager.generateSuggestions(from: homeManager.accessories)
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Smart Group Suggestions")
                .font(.largeTitle)
                .bold()
                .padding(.top, 60)

            Text("We've found these potential groups based on your accessories")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 80)

            ScrollView {
                VStack(spacing: 20) {
                    ForEach(suggestions) { suggestion in
                        HStack(spacing: 25) {
                            Image(systemName: suggestion.icon)
                                .font(.system(size: 40))
                                .foregroundColor(colorForName(suggestion.color))
                                .frame(width: 60)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(suggestion.name)
                                    .font(.title3)
                                    .bold()

                                Text("\(suggestion.accessoryIDs.count) accessories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                groupManager.createGroup(
                                    name: suggestion.name,
                                    icon: suggestion.icon,
                                    color: suggestion.color,
                                    accessoryIDs: suggestion.accessoryIDs
                                )
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add")
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
                        .padding(25)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                    }
                }
                .padding(.horizontal, 80)
            }

            Button("Done") {
                isPresented = false
            }
            .font(.title2)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 80)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .buttonStyle(.plain)
            .padding(.bottom, 40)
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

#Preview {
    ServiceGroupsView()
        .environmentObject(HomeKitManager())
}
