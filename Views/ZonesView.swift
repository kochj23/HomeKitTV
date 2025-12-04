import SwiftUI
import HomeKit

/// Zones Management View
///
/// Interface for managing home zones (groups of rooms):
/// - Create/edit/delete zones
/// - Group accessories into zones (e.g., "Upstairs", "Guest House")
/// - Control entire zones at once
/// - Zone-based scenes
/// - Visual zone layout
///
/// **Backend Integration**: Uses ZoneManager.shared
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Uses @ObservedObject to prevent retain cycles
///
/// **Features**:
/// - Drag-and-drop room assignment
/// - Zone-wide control (all lights on/off)
/// - Zone statistics
/// - Custom icons and colors
///
/// - SeeAlso: `ZoneManager`, `Zone`
struct ZonesView: View {
    @ObservedObject private var zoneManager = ZoneManager.shared
    @EnvironmentObject var homeManager: HomeKitManager

    @State private var showingEditor = false
    @State private var editingZone: Zone?
    @State private var selectedZone: Zone?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // Header
                headerSection

                // Statistics
                statisticsSection

                // Zones Grid
                zonesGridSection

                // Zone Details (if selected)
                if let zone = selectedZone {
                    zoneDetailsSection(zone)
                }

                // Unassigned Rooms
                unassignedRoomsSection
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 60)
        }
        .sheet(isPresented: $showingEditor) {
            zoneEditorSheet
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Zones")
                    .font(.largeTitle)
                    .bold()
                Text("Organize rooms into logical zones for easier control")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                editingZone = nil
                showingEditor = true
            }) {
                Label("New Zone", systemImage: "plus.circle.fill")
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
        let totalAccessories = zoneManager.zones.reduce(0) { count, zone in
            count + zoneAccessories(zone).count
        }

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 30) {
            StatCard(
                title: "Total Zones",
                value: "\(zoneManager.zones.count)",
                icon: "square.grid.2x2.fill",
                color: .blue
            )

            StatCard(
                title: "Total Rooms",
                value: "\(homeManager.rooms.count)",
                icon: "house.fill",
                color: .green
            )

            StatCard(
                title: "Accessories in Zones",
                value: "\(totalAccessories)",
                icon: "apps.iphone",
                color: .purple
            )
        }
    }

    // MARK: - Zones Grid

    private var zonesGridSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Zones")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            if zoneManager.zones.isEmpty {
                emptyStateView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(zoneManager.zones) { zone in
                        ZoneCard(zone: zone, isSelected: selectedZone?.id == zone.id) {
                            selectedZone = zone
                        } onEdit: {
                            editingZone = zone
                            showingEditor = true
                        } onControlAll: { action in
                            controlZone(zone, action: action)
                        }
                        .environmentObject(homeManager)
                    }
                }
            }
        }
    }

    // MARK: - Zone Details Section

    private func zoneDetailsSection(_ zone: Zone) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Zone: \(zone.name)")
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                Spacer()

                Button("Close") {
                    selectedZone = nil
                }
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
            }

            // Rooms in Zone
            Text("Rooms (\(zoneRooms(zone).count))")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(zoneRooms(zone), id: \.uniqueIdentifier) { room in
                    RoomInZoneCard(room: room, accessoryCount: homeManager.accessories(for: room).count)
                }
            }

            // Accessories in Zone
            Text("Accessories (\(zoneAccessories(zone).count))")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(zoneAccessories(zone), id: \.uniqueIdentifier) { accessory in
                    AccessoryMiniCard(accessory: accessory)
                }
            }
        }
        .padding(30)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }

    // MARK: - Unassigned Rooms

    private var unassignedRoomsSection: some View {
        let unassigned = unassignedRooms

        return VStack(alignment: .leading, spacing: 20) {
            Text("Unassigned Rooms (\(unassigned.count))")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            if unassigned.isEmpty {
                Text("All rooms are assigned to zones")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.secondary)
                    .padding(20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(unassigned, id: \.uniqueIdentifier) { room in
                        UnassignedRoomCard(room: room, accessoryCount: homeManager.accessories(for: room).count)
                    }
                }
            }
        }
    }

    // MARK: - Zone Editor Sheet

    private var zoneEditorSheet: some View {
        ZoneEditorView(zone: editingZone, isPresented: $showingEditor)
            .environmentObject(homeManager)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No zones yet")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
            Text("Create zones to group rooms together")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Helper Methods

    private func zoneRooms(_ zone: Zone) -> [HMRoom] {
        guard let home = homeManager.currentHome else { return [] }
        return zoneManager.rooms(for: zone, in: home)
    }

    private func zoneAccessories(_ zone: Zone) -> [HMAccessory] {
        guard let home = homeManager.currentHome else { return [] }
        return zoneManager.accessories(for: zone, in: home)
    }

    private var unassignedRooms: [HMRoom] {
        let allAssignedRoomIDs = zoneManager.zones.flatMap { $0.roomIDs }
        return homeManager.rooms.filter { !allAssignedRoomIDs.contains($0.uniqueIdentifier) }
    }

    private func controlZone(_ zone: Zone, action: ZoneAction) {
        let accessories = zoneAccessories(zone)

        switch action {
        case .allOn:
            for accessory in accessories {
                // Turn on if not already on
                if !homeManager.getPowerState(accessory) {
                    homeManager.toggleAccessory(accessory)
                }
            }
            homeManager.statusMessage = "Turned on all accessories in \(zone.name)"

        case .allOff:
            for accessory in accessories {
                // Turn off if not already off
                if homeManager.getPowerState(accessory) {
                    homeManager.toggleAccessory(accessory)
                }
            }
            homeManager.statusMessage = "Turned off all accessories in \(zone.name)"
        }
    }
}

// MARK: - Zone Action

enum ZoneAction {
    case allOn
    case allOff
}

// MARK: - Zone Card

struct ZoneCard: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var zoneManager = ZoneManager.shared

    let zone: Zone
    let isSelected: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onControlAll: (ZoneAction) -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: zone.iconName)
                        .font(.title)
                        .foregroundColor(colorForZone)

                    Spacer()

                    if #available(tvOS 17.0, *) {
                        Menu {
                            Button("Turn All On") {
                                onControlAll(.allOn)
                            }

                            Button("Turn All Off") {
                                onControlAll(.allOff)
                            }

                            Button("Edit Zone") {
                                onEdit()
                            }

                            Button("Delete Zone", role: .destructive) {
                                zoneManager.deleteZone(zone)
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: onEdit) {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(zone.name)
                    .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .bold()

                HStack {
                    Label("\(roomCount) rooms", systemImage: "house")
                    Text("•")
                        .foregroundColor(.secondary)
                    Label("\(accessoryCount) devices", systemImage: "apps.iphone")
                }
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
            }
            .padding(25)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? colorForZone.opacity(0.2) : Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? colorForZone : Color.clear, lineWidth: 3)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var colorForZone: Color {
        switch zone.colorName {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        default: return .blue
        }
    }

    private var roomCount: Int {
        guard let home = homeManager.currentHome else { return 0 }
        return zoneManager.rooms(for: zone, in: home).count
    }

    private var accessoryCount: Int {
        guard let home = homeManager.currentHome else { return 0 }
        return zoneManager.accessories(for: zone, in: home).count
    }
}

// MARK: - Room in Zone Card

struct RoomInZoneCard: View {
    let room: HMRoom
    let accessoryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.blue)
                Spacer()
            }

            Text(room.name)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            Text("\(accessoryCount) accessories")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Accessory Mini Card

struct AccessoryMiniCard: View {
    let accessory: HMAccessory

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconForAccessory)
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(accessory.isReachable ? .blue : .gray)

            Text(accessory.name)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var iconForAccessory: String {
        // Get primary service icon
        if let service = accessory.services.first {
            switch service.serviceType {
            case HMServiceTypeLightbulb: return "lightbulb.fill"
            case HMServiceTypeOutlet: return "powerplug.fill"
            case HMServiceTypeSwitch: return "switch.2"
            case HMServiceTypeThermostat: return "thermometer"
            case HMServiceTypeFan: return "fan.fill"
            case HMServiceTypeLockMechanism: return "lock.fill"
            case HMServiceTypeGarageDoorOpener: return "garage"
            default: return "app.connected.to.app.below.fill"
            }
        }
        return "app.connected.to.app.below.fill"
    }
}

// MARK: - Unassigned Room Card

struct UnassignedRoomCard: View {
    let room: HMRoom
    let accessoryCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundColor(.orange)
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
            }

            Text(room.name)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            Text("\(accessoryCount) accessories")
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Zone Editor View

struct ZoneEditorView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var zoneManager = ZoneManager.shared

    let zone: Zone?
    @Binding var isPresented: Bool

    @State private var name: String
    @State private var iconName: String
    @State private var colorName: String
    @State private var selectedRoomIDs: Set<UUID>

    init(zone: Zone?, isPresented: Binding<Bool>) {
        self.zone = zone
        self._isPresented = isPresented

        if let zone = zone {
            self._name = State(initialValue: zone.name)
            self._iconName = State(initialValue: zone.iconName)
            self._colorName = State(initialValue: zone.colorName)
            self._selectedRoomIDs = State(initialValue: Set(zone.roomIDs))
        } else {
            self._name = State(initialValue: "New Zone")
            self._iconName = State(initialValue: "square.grid.2x2")
            self._colorName = State(initialValue: "blue")
            self._selectedRoomIDs = State(initialValue: [])
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Basic Info
                    basicInfoSection

                    // Room Selection
                    roomSelectionSection

                    // Buttons
                    buttonsSection
                }
                .padding(40)
            }
            .navigationTitle(zone == nil ? "New Zone" : "Edit Zone")
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

            TextField("Zone Name", text: $name)
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .textFieldStyle(.plain)
                .padding(15)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            HStack {
                Text("Icon:")
                Picker("Icon", selection: $iconName) {
                    Text("Grid").tag("square.grid.2x2")
                    Text("House").tag("house.fill")
                    Text("Building").tag("building.2.fill")
                    Text("Bed").tag("bed.double.fill")
                    Text("Fork & Knife").tag("fork.knife")
                    Text("Tree").tag("tree.fill")
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
                }
                .frame(width: 300)
            }
        }
        .padding(25)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var roomSelectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Rooms (\(selectedRoomIDs.count) selected)")
                .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .bold()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 15) {
                ForEach(homeManager.rooms, id: \.uniqueIdentifier) { room in
                    RoomSelectionCard(
                        room: room,
                        isSelected: selectedRoomIDs.contains(room.uniqueIdentifier)
                    ) {
                        toggleRoom(room)
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

            Button("Save Zone") {
                saveZone()
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

    private func toggleRoom(_ room: HMRoom) {
        if selectedRoomIDs.contains(room.uniqueIdentifier) {
            selectedRoomIDs.remove(room.uniqueIdentifier)
        } else {
            selectedRoomIDs.insert(room.uniqueIdentifier)
        }
    }

    private func saveZone() {
        if let existing = zone {
            var updated = existing
            updated.name = name
            updated.iconName = iconName
            updated.colorName = colorName
            updated.roomIDs = Array(selectedRoomIDs)
            zoneManager.updateZone(updated)
        } else {
            _ = zoneManager.createZone(
                name: name,
                roomIDs: Array(selectedRoomIDs),
                iconName: iconName,
                colorName: colorName
            )
        }

        isPresented = false
    }
}

// MARK: - Room Selection Card

struct RoomSelectionCard: View {
    let room: HMRoom
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(room.name)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)

                Spacer()
            }
            .padding(15)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 35, weight: .bold))

            Text(title)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Preview

#Preview {
    ZonesView()
        .environmentObject(HomeKitManager())
}
