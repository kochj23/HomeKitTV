import SwiftUI
import HomeKit

/// Main content view with tab-based navigation
///
/// This view provides the primary navigation structure for the app with enhanced features:
/// - Home: Overview with favorites and quick access
/// - Rooms: Grid view of all rooms with search
/// - Scenes: Grid view and management
/// - Accessories: Grid view with filtering
/// - More: Settings, automations, history
///
/// **Features**:
/// - Tab-based navigation optimized for tvOS
/// - Quick controls panel
/// - Search and filter
/// - Pull-to-refresh
/// - Settings and advanced features
///
/// - SeeAlso: `HomeView`, `RoomsView`, `ScenesView`, `AccessoriesView`
struct ContentView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var selectedTab = 0
    @State private var showingQuickControls = false
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            // Glassmorphic background
            GlassmorphicBackground()

            TabView(selection: $selectedTab) {
                HomeView(showingQuickControls: $showingQuickControls)
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                RoomsView()
                    .tabItem {
                        Label("Rooms", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(1)

                ScenesView()
                    .tabItem {
                        Label("Scenes", systemImage: "lightbulb.fill")
                    }
                    .tag(2)

                AccessoriesView()
                    .tabItem {
                        Label("Accessories", systemImage: "apps.iphone")
                    }
                    .tag(3)

                HelpView()
                    .tabItem {
                        Label("Help", systemImage: "questionmark.circle.fill")
                    }
                    .tag(4)

                MoreView(showingSettings: $showingSettings)
                    .tabItem {
                        Label("More", systemImage: "ellipsis.circle.fill")
                    }
                    .tag(5)
            }
            .overlay(alignment: .bottom) {
                if !homeManager.statusMessage.isEmpty {
                    VStack(spacing: 10) {
                        HStack {
                            Spacer()

                            Button(action: {
                                homeManager.statusMessage = ""
                                homeManager.failedAccessories = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 5)

                        Text(homeManager.statusMessage)
                            .font(.body)
                            .bold()
                            .multilineTextAlignment(.center)

                        // Show failed device count if any
                        if !homeManager.failedAccessories.isEmpty {
                            Text("Tap for details or wait to auto-dismiss")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 120)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onTapGesture {
                        homeManager.statusMessage = ""
                        homeManager.failedAccessories = []
                    }
                }
            }

            // Quick Controls Overlay
            if showingQuickControls {
                QuickControlsPanel(isPresented: $showingQuickControls)
                    .environmentObject(homeManager)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(homeManager)
        }
    }
}

/// Home dashboard view showing overview of scenes and rooms
///
/// This view displays:
/// - Loading state with progress indicator
/// - Authorization prompt if HomeKit not available
/// - Quick controls button
/// - Favorite accessories and scenes
/// - Recent activity
/// - Home name as title
/// - Grid of all rooms
/// - Empty state messaging
///
/// **Layout**: Optimized for tvOS with large padding and touch targets
struct HomeView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @Binding var showingQuickControls: Bool

    var favoriteAccessories: [HMAccessory] {
        homeManager.favoriteAccessories()
    }

    var favoriteScenes: [HMActionSet] {
        homeManager.favoriteScenes()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                if homeManager.isLoading {
                    VStack(spacing: 30) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading HomeKit...")
                            .font(.title2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(100)
                } else if !homeManager.isAuthorized {
                    VStack(spacing: 30) {
                        Image(systemName: "homekit")
                            .font(.system(size: 100))
                            .foregroundColor(.secondary)
                        Text("HomeKit Not Available")
                            .font(.title)
                        Text("Please set up HomeKit on your iOS device")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(100)
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(homeManager.primaryHome?.name ?? "My Home")
                                .font(.largeTitle)
                                .bold()
                            Text("\(homeManager.filteredAccessories.count) accessories")
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            showingQuickControls = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "star.circle.fill")
                                Text("Quick Controls")
                            }
                            .font(.title3)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 40)

                    // Widget Dashboard - TODO: Add to Xcode project
                    // WidgetDashboard()
                    //     .environmentObject(homeManager)

                    // Home Status Dashboard
                    HomeDashboardStatusView()
                        .environmentObject(homeManager)
                        .padding(.horizontal, 80)

                    // Favorite Accessories
                    if !favoriteAccessories.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Favorite Accessories")
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 60)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(favoriteAccessories.prefix(6), id: \.uniqueIdentifier) { accessory in
                                        AccessoryCard(accessory: accessory)
                                    }
                                }
                                .padding(.horizontal, 60)
                            }
                        }
                    }

                    // Favorite Scenes
                    if !favoriteScenes.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Favorite Scenes")
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 60)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(favoriteScenes.prefix(6), id: \.uniqueIdentifier) { scene in
                                        SceneCard(scene: scene)
                                    }
                                }
                                .padding(.horizontal, 60)
                            }
                        }
                    }

                    if !homeManager.filteredScenes.isEmpty && favoriteScenes.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Scenes")
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 60)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(homeManager.filteredScenes.prefix(6), id: \.uniqueIdentifier) { scene in
                                        SceneCard(scene: scene)
                                    }
                                }
                                .padding(.horizontal, 60)
                            }
                        }
                    }

                    if !homeManager.filteredRooms.isEmpty {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Rooms")
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 60)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 25)], spacing: 25) {
                                ForEach(homeManager.filteredRooms, id: \.uniqueIdentifier) { room in
                                    RoomCard(room: room)
                                }
                            }
                            .padding(.horizontal, 60)
                        }
                    }

                    if homeManager.filteredAccessories.isEmpty && homeManager.filteredScenes.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "homekit")
                                .font(.system(size: 100))
                                .foregroundColor(.secondary)
                            Text("No Accessories Found")
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("Add accessories using the Home app on iOS")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    }
                }
            }
            .padding(.bottom, 200)
        }
    }
}

/// Rooms tab view showing all rooms in a grid
///
/// Displays a grid of room cards with navigation to room detail views.
///
/// **Features**:
/// - Dynamic sizing to fit all rooms on one screen
/// - Navigation to `RoomDetailView` on selection
/// - Empty state for when no rooms exist
///
/// **Layout**: Dynamic grid that scales to fit all content without scrolling
struct RoomsView: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 15) {
                    Text("Rooms")
                        .scaledTitle2Font()
                        .bold()
                        .padding(.horizontal, 40)
                        .padding(.top, 20)

                    if homeManager.filteredRooms.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 80))
                                .foregroundColor(.secondary)
                            Text("No Rooms")
                                .scaledTitle2Font()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        let itemCount = homeManager.filteredRooms.count
                        let cardSize = DynamicLayoutCalculator.calculateCardSize(
                            itemCount: itemCount,
                            availableWidth: geometry.size.width,
                            availableHeight: geometry.size.height,
                            headerHeight: 80
                        )
                        let columns = calculateColumns(for: itemCount, width: geometry.size.width)
                        let spacing = DynamicLayoutCalculator.gridSpacing(for: geometry.size.width, columns: columns)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                            ForEach(homeManager.filteredRooms, id: \.uniqueIdentifier) { room in
                                NavigationLink(destination: RoomDetailView(room: room)) {
                                    DynamicRoomCard(room: room, size: cardSize)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
    }

    private func calculateColumns(for itemCount: Int, width: CGFloat) -> Int {
        switch itemCount {
        case 0...4: return min(itemCount, 4)
        case 5...8: return 4
        case 9...12: return 4
        case 13...16: return 5
        case 17...20: return 5
        default: return 6
        }
    }
}

/// Scenes tab view showing all HomeKit scenes
///
/// Displays a grid of scene cards that can be tapped to execute.
///
/// **Features**:
/// - Dynamic sizing to fit all scenes on one screen
/// - Direct scene execution on tap
/// - Empty state with instructions
///
/// **Layout**: Dynamic grid that scales to fit all content without scrolling
struct ScenesView: View {
    @EnvironmentObject var homeManager: HomeKitManager

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 15) {
                Text("Scenes")
                    .scaledTitle2Font()
                    .bold()
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                if homeManager.filteredScenes.isEmpty {
                    VStack(spacing: 30) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 80))
                            .foregroundColor(.secondary)
                        Text("No Scenes")
                            .scaledTitle2Font()
                        Text("Create scenes in the Home app on iOS")
                            .scaledBodyFont()
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    let itemCount = homeManager.filteredScenes.count
                    let cardSize = DynamicLayoutCalculator.calculateCardSize(
                        itemCount: itemCount,
                        availableWidth: geometry.size.width,
                        availableHeight: geometry.size.height,
                        headerHeight: 80
                    )
                    let columns = calculateColumns(for: itemCount, width: geometry.size.width)
                    let spacing = DynamicLayoutCalculator.gridSpacing(for: geometry.size.width, columns: columns)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                        ForEach(homeManager.filteredScenes, id: \.uniqueIdentifier) { scene in
                            DynamicSceneCard(scene: scene, size: cardSize)
                        }
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }

    private func calculateColumns(for itemCount: Int, width: CGFloat) -> Int {
        switch itemCount {
        case 0...4: return min(itemCount, 4)
        case 5...8: return 4
        case 9...12: return 5
        case 13...16: return 6
        case 17...20: return 6
        default: return 7
        }
    }
}

/// Accessories tab view showing all HomeKit accessories
///
/// Displays a grid of all accessories with navigation to detail views.
///
/// **Features**:
/// - Adaptive grid layout
/// - Navigation to `AccessoryDetailView` on selection
/// - Empty state messaging
///
/// **Layout**: Grid with 400pt minimum column width
struct AccessoriesView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @StateObject var selectionManager = SelectionManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        Text("All Accessories")
                            .font(.largeTitle)
                            .bold()

                        Spacer()

                        // Selection mode toggle
                        Button(action: {
                            if selectionManager.isSelectionMode {
                                selectionManager.exitSelectionMode()
                            } else {
                                selectionManager.enterSelectionMode()
                            }
                        }) {
                            HStack {
                                Image(systemName: selectionManager.isSelectionMode ? "xmark.circle.fill" : "checkmark.circle")
                                Text(selectionManager.isSelectionMode ? "Cancel" : "Select")
                            }
                            .font(.title3)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(selectionManager.isSelectionMode ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 60)
                    .padding(.top, 40)

                    if homeManager.filteredAccessories.isEmpty {
                        VStack(spacing: 30) {
                            Image(systemName: "apps.iphone")
                                .font(.system(size: 100))
                                .foregroundColor(.secondary)
                            Text("No Accessories")
                                .font(.title)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(100)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 350), spacing: 25)], spacing: 25) {
                            ForEach(homeManager.filteredAccessories, id: \.uniqueIdentifier) { accessory in
                                if selectionManager.isSelectionMode {
                                    // Selection mode: tap to toggle selection
                                    Button(action: {
                                        selectionManager.toggleSelection(accessory)
                                    }) {
                                        ZStack(alignment: .topLeading) {
                                            AccessoryCard(accessory: accessory)

                                            // Selection checkbox overlay
                                            Image(systemName: selectionManager.isSelected(accessory) ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 40))
                                                .foregroundColor(selectionManager.isSelected(accessory) ? .green : .white)
                                                .background(
                                                    Circle()
                                                        .fill(Color.black.opacity(0.5))
                                                        .frame(width: 50, height: 50)
                                                )
                                                .padding(15)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    // Normal mode: navigate to detail view
                                    NavigationLink(destination: AccessoryDetailView(accessory: accessory)) {
                                        AccessoryCard(accessory: accessory)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, 60)
                    }
                }
                .padding(.bottom, selectionManager.isSelectionMode ? 200 : 200)
            }

            // Bulk Action Toolbar
            if selectionManager.isSelectionMode && !selectionManager.selectedAccessories.isEmpty {
                VStack(spacing: 0) {
                    // Status message
                    if !selectionManager.bulkOperationStatus.isEmpty {
                        Text(selectionManager.bulkOperationStatus)
                            .font(.title3)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.green.opacity(0.2))
                    }

                    HStack(spacing: 30) {
                        // Selected count
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(selectionManager.selectedAccessories.count) Selected")
                                .font(.title2)
                                .bold()

                            Button(action: {
                                selectionManager.selectAll(homeManager.accessories)
                            }) {
                                Text("Select All (\(homeManager.accessories.count))")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // Bulk actions
                        HStack(spacing: 20) {
                            // Turn All On
                            Button(action: {
                                selectionManager.bulkPowerToggle(
                                    accessories: homeManager.accessories,
                                    turnOn: true
                                ) { success, failed in
                                    print("Bulk On: \(success) succeeded, \(failed) failed")
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "power.circle.fill")
                                        .font(.system(size: 40))
                                    Text("Turn On")
                                        .font(.caption)
                                }
                                .frame(width: 120, height: 100)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)

                            // Turn All Off
                            Button(action: {
                                selectionManager.bulkPowerToggle(
                                    accessories: homeManager.accessories,
                                    turnOn: false
                                ) { success, failed in
                                    print("Bulk Off: \(success) succeeded, \(failed) failed")
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "power.circle")
                                        .font(.system(size: 40))
                                    Text("Turn Off")
                                        .font(.caption)
                                }
                                .frame(width: 120, height: 100)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)

                            // Clear Selection
                            Button(action: {
                                selectionManager.clearSelection()
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.red)
                                    Text("Clear")
                                        .font(.caption)
                                }
                                .frame(width: 120, height: 100)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(40)
                    .background(.ultraThinMaterial)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

/// More menu view with advanced features
///
/// Provides navigation to:
/// - Settings
/// - Activity History
/// - Automation Management
/// - Scene Management
/// - Energy Dashboard
/// - Notification Center
/// - Routines
/// - Zones
/// - Diagnostics
/// - Hub Status
struct MoreView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @Binding var showingSettings: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 15) {
                    Text("More")
                        .scaledTitle2Font()
                        .bold()
                        .padding(.horizontal, 40)
                        .padding(.top, 20)

                    // All menu items in single grid (no sections)
                    let itemCount = 10  // Total active menu items
                    let cardSize = DynamicLayoutCalculator.calculateCardSize(
                        itemCount: itemCount,
                        availableWidth: geometry.size.width,
                        availableHeight: geometry.size.height,
                        headerHeight: 80
                    )
                    let columns = calculateColumns(for: itemCount)
                    let spacing = DynamicLayoutCalculator.gridSpacing(for: geometry.size.width, columns: columns)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns), spacing: spacing) {
                        // Settings
                        Button(action: {
                            showingSettings = true
                        }) {
                            MoreMenuItem(
                                title: "Settings",
                                icon: "gearshape.fill",
                                description: "Preferences and configuration",
                                color: .blue
                            )
                        }
                        .buttonStyle(.plain)

                        // Activity History
                        NavigationLink(destination: ActivityHistoryView()) {
                            MoreMenuItem(
                                title: "Activity History",
                                icon: "clock.arrow.circlepath",
                                description: "View recent actions",
                                color: .green
                            )
                        }
                        .buttonStyle(.plain)

                        // Automations
                        NavigationLink(destination: AutomationView()) {
                            MoreMenuItem(
                                title: "Automations",
                                icon: "gearshape.2.fill",
                                description: "Manage automations",
                                color: .orange
                            )
                        }
                        .buttonStyle(.plain)

                        // Scene Management
                        NavigationLink(destination: SceneManagementView()) {
                            MoreMenuItem(
                                title: "Scene Management",
                                icon: "sparkles",
                                description: "Create and edit scenes",
                                color: .purple
                            )
                        }
                        .buttonStyle(.plain)

                        // Energy Dashboard
                        NavigationLink(destination: EnergyDashboardView()) {
                            MoreMenuItem(
                                title: "Energy Dashboard",
                                icon: "bolt.fill",
                                description: "Monitor energy consumption",
                                color: .yellow
                            )
                        }
                        .buttonStyle(.plain)

                        // Notification Center
                        NavigationLink(destination: NotificationCenterView()) {
                            MoreMenuItem(
                                title: "Notification Center",
                                icon: "bell.fill",
                                description: "View and manage alerts",
                                color: .red
                            )
                        }
                        .buttonStyle(.plain)

                        // Routines
                        NavigationLink(destination: RoutinesView()) {
                            MoreMenuItem(
                                title: "Routines",
                                icon: "sparkles",
                                description: "Multi-step automations",
                                color: .purple
                            )
                        }
                        .buttonStyle(.plain)

                        // Zones
                        NavigationLink(destination: ZonesView()) {
                            MoreMenuItem(
                                title: "Zones",
                                icon: "square.grid.2x2.fill",
                                description: "Group rooms into zones",
                                color: .cyan
                            )
                        }
                        .buttonStyle(.plain)

                        // Accessory Diagnostics
                        NavigationLink(destination: AccessoryDiagnosticsView()) {
                            MoreMenuItem(
                                title: "Accessory Diagnostics",
                                icon: "stethoscope",
                                description: "Health and troubleshooting",
                                color: .pink
                            )
                        }
                        .buttonStyle(.plain)

                        // Hub Status
                        NavigationLink(destination: HubStatusView()) {
                            MoreMenuItem(
                                title: "Hub Status",
                                icon: "appletv.fill",
                                description: "Monitor hub connectivity",
                                color: .indigo
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 40)
                }
            }
        }
    }

    private func calculateColumns(for itemCount: Int) -> Int {
        switch itemCount {
        case 0...4: return min(itemCount, 4)
        case 5...8: return 4
        case 9...12: return 4
        default: return 5
        }
    }
}

/// Menu item card for More view
struct MoreMenuItem: View {
    let title: String
    let icon: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(color)
                .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
        }
        .padding(25)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    ContentView()
        .environmentObject(HomeKitManager())
}
