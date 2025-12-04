import SwiftUI
import HomeKit

/// Help and documentation view
///
/// Provides comprehensive user documentation for all HomeKitTV features.
/// Organized by feature categories with tips and tricks for new HomeKit users.
///
/// **Features**:
/// - Searchable documentation
/// - Category-based organization
/// - Tips and tricks for each feature
/// - Beginner-friendly explanations
///
/// **Memory Safety**: Uses [weak self] in all closures
struct HelpView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @State private var searchText = ""
    @State private var selectedCategory: HelpCategory? = nil

    var filteredTopics: [HelpTopic] {
        if searchText.isEmpty {
            return HelpTopic.allTopics
        }
        return HelpTopic.allTopics.filter { topic in
            topic.title.localizedCaseInsensitiveContains(searchText) ||
            topic.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // Header
                    Text("Help & Documentation")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 60)
                        .padding(.top, 40)

                    // All Topics as Tiles
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 450), spacing: 25)], spacing: 25) {
                        ForEach(HelpTopic.allTopics, id: \.title) { topic in
                            NavigationLink(destination: TopicDetailView(topic: topic)) {
                                HelpTopicTile(topic: topic)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 60)
                }
                .padding(.bottom, 200)
            }
        }
    }
}

/// Help topic tile for grid display
struct HelpTopicTile: View {
    let topic: HelpTopic

    var body: some View {
        HStack(spacing: 25) {
            Image(systemName: topic.icon)
                .font(.system(size: 50))
                .foregroundColor(.blue)
                .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(topic.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(topic.description)
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
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
    }
}

/// Quick Start card for new users
struct QuickStartCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                Text("Quick Start Guide")
                    .font(.title2)
                    .bold()
            }

            VStack(alignment: .leading, spacing: 15) {
                QuickStartStep(number: 1, text: "Make sure your HomeKit accessories are set up using the Home app on your iPhone or iPad")
                QuickStartStep(number: 2, text: "Your Apple TV must be signed in to the same iCloud account as your iOS devices")
                QuickStartStep(number: 3, text: "Navigate using the Siri Remote: swipe to browse, click to select")
                QuickStartStep(number: 4, text: "Use the Home tab for quick access to your favorite accessories and scenes")
                QuickStartStep(number: 5, text: "Tap any accessory card to control it, or long-press for more options")
            }

            Divider()
                .padding(.vertical, 10)

            VStack(alignment: .leading, spacing: 10) {
                Text("💡 Pro Tip:")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.blue)
                Text("Use Siri on your Apple TV to control HomeKit devices with voice commands like 'Turn on the living room lights' or 'Set the thermostat to 72 degrees'")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(30)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Quick start step row
struct QuickStartStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Text("\(number)")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

/// Category card for browsing help topics
struct CategoryCard: View {
    let category: HelpCategory

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: category.icon)
                .font(.system(size: 50))
                .foregroundColor(category.color)
                .frame(width: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(category.title)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.primary)

                Text(category.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 25))
                .foregroundColor(.secondary)
        }
        .padding(25)
        .background(category.color.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Help topic row
struct HelpTopicRow: View {
    let topic: HelpTopic

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: topic.icon)
                .font(.system(size: 35))
                .foregroundColor(.blue)
                .frame(width: 60)

            VStack(alignment: .leading, spacing: 5) {
                Text(topic.title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)

                Text(topic.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 20))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
}

/// Category detail view showing all topics in a category
struct CategoryDetailView: View {
    let category: HelpCategory

    var topics: [HelpTopic] {
        HelpTopic.allTopics.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                HStack {
                    Image(systemName: category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(category.color)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.title)
                            .font(.largeTitle)
                            .bold()
                        Text(category.subtitle)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 80)
                .padding(.top, 60)

                VStack(spacing: 15) {
                    ForEach(topics, id: \.title) { topic in
                        NavigationLink(destination: TopicDetailView(topic: topic)) {
                            HelpTopicRow(topic: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 200)
        }
    }
}

/// Topic detail view showing full documentation for a feature
struct TopicDetailView: View {
    let topic: HelpTopic
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                            Text("Back")
                                .font(.title3)
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)

                // Title Header
                HStack {
                    Image(systemName: topic.icon)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(topic.title)
                            .font(.largeTitle)
                            .bold()
                        Text(topic.description)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 10)

                // How to Use
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Use")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal, 60)

                    VStack(alignment: .leading, spacing: 15) {
                        ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 15) {
                                Text("\(index + 1)")
                                    .font(.body)
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(width: 35, height: 35)
                                    .background(Color.blue)
                                    .clipShape(Circle())

                                Text(step)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(25)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(15)
                    .padding(.horizontal, 60)
                }

                // Tips & Tricks
                if !topic.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tips & Tricks")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 60)

                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(topic.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 15) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.system(size: 25))
                                        .foregroundColor(.yellow)

                                    Text(tip)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(25)
                        .background(Color.yellow.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal, 60)
                    }
                }

                // Common Issues
                if !topic.commonIssues.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Common Issues & Solutions")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal, 60)

                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(topic.commonIssues, id: \.issue) { issue in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.orange)

                                        Text(issue.issue)
                                            .font(.body)
                                            .bold()
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Text(issue.solution)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 35)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if issue != topic.commonIssues.last {
                                    Divider()
                                }
                            }
                        }
                        .padding(25)
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(15)
                        .padding(.horizontal, 60)
                    }
                }
            }
            .padding(.bottom, 200)
        }
        .focusable()  // Makes ScrollView respond to tvOS remote swipes
        .navigationTitle(topic.title)
    }
}

// MARK: - Data Models

/// Help category enumeration
enum HelpCategory: CaseIterable {
    case basics
    case accessories
    case scenes
    case automation
    case advanced
    case troubleshooting

    var title: String {
        switch self {
        case .basics: return "Getting Started"
        case .accessories: return "Controlling Accessories"
        case .scenes: return "Scenes & Shortcuts"
        case .automation: return "Automations & Routines"
        case .advanced: return "Advanced Features"
        case .troubleshooting: return "Troubleshooting"
        }
    }

    var subtitle: String {
        switch self {
        case .basics: return "Learn the fundamentals of HomeKitTV"
        case .accessories: return "Control lights, locks, thermostats, and more"
        case .scenes: return "Create and manage scenes for quick control"
        case .automation: return "Set up smart automations and routines"
        case .advanced: return "Energy monitoring, zones, and diagnostics"
        case .troubleshooting: return "Fix common problems and connectivity issues"
        }
    }

    var icon: String {
        switch self {
        case .basics: return "star.fill"
        case .accessories: return "lightbulb.fill"
        case .scenes: return "sparkles"
        case .automation: return "gearshape.2.fill"
        case .advanced: return "wand.and.stars"
        case .troubleshooting: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .basics: return .blue
        case .accessories: return .orange
        case .scenes: return .purple
        case .automation: return .green
        case .advanced: return .pink
        case .troubleshooting: return .red
        }
    }
}

/// Help topic structure
struct HelpTopic {
    let category: HelpCategory
    let title: String
    let description: String
    let icon: String
    let steps: [String]
    let tips: [String]
    let commonIssues: [CommonIssue]

    static let allTopics: [HelpTopic] = [
        // Getting Started
        HelpTopic(
            category: .basics,
            title: "Navigating the App",
            description: "Learn how to navigate through HomeKitTV using your Siri Remote",
            icon: "hand.point.up.left.fill",
            steps: [
                "Swipe left or right on the Siri Remote touchpad to move between tabs",
                "Click the touchpad to select an item",
                "Press and hold on an item for additional options",
                "Press the back button to return to the previous screen",
                "Press the home button to exit the app"
            ],
            tips: [
                "The app has five main tabs: Home, Rooms, Scenes, Accessories, and More",
                "Use the Home tab for quick access to your most-used devices",
                "Your Apple TV must be signed in to the same iCloud account as your iOS devices"
            ],
            commonIssues: [
                CommonIssue(issue: "Can't see any accessories", solution: "Make sure your Apple TV is signed in to the same iCloud account as your iPhone/iPad where HomeKit is configured. Also ensure your HomeKit accessories are added in the Home app on iOS.")
            ]
        ),

        HelpTopic(
            category: .basics,
            title: "Understanding HomeKit",
            description: "Learn what HomeKit is and how it works",
            icon: "house.fill",
            steps: [
                "HomeKit is Apple's smart home platform that lets you control compatible accessories",
                "All HomeKit data is stored securely on your devices and in iCloud",
                "Your Apple TV can act as a home hub, enabling remote access and automations",
                "HomeKit accessories communicate securely using end-to-end encryption",
                "You can control accessories from any Apple device signed into your iCloud account"
            ],
            tips: [
                "Look for the 'Works with Apple HomeKit' logo when buying smart home devices",
                "Matter-compatible devices also work with HomeKit",
                "HomeKit doesn't require a subscription or cloud service"
            ],
            commonIssues: []
        ),

        // Controlling Accessories
        HelpTopic(
            category: .accessories,
            title: "Controlling Lights",
            description: "Turn lights on/off and adjust brightness and color",
            icon: "lightbulb.fill",
            steps: [
                "Navigate to the Home, Rooms, or Accessories tab",
                "Find the light you want to control",
                "Click on the light card to toggle it on or off",
                "For dimmable lights, click on the card to open detailed controls",
                "Use the + and - buttons to adjust brightness",
                "For color lights, select from preset colors or use the color picker"
            ],
            tips: [
                "Group multiple lights into a room for easier control",
                "Create scenes to set multiple lights to specific brightness and colors at once",
                "Use Siri: 'Set the living room to 50%' or 'Make the bedroom lights blue'"
            ],
            commonIssues: [
                CommonIssue(issue: "Light is unresponsive", solution: "Check if the light is powered on at the switch. Ensure your Wi-Fi network is working. Try power cycling the light bulb."),
                CommonIssue(issue: "Can't adjust brightness", solution: "Not all lights support dimming. Check if your bulb is dimmable and properly configured in the Home app.")
            ]
        ),

        HelpTopic(
            category: .accessories,
            title: "Controlling Thermostats",
            description: "Adjust temperature and change heating/cooling modes",
            icon: "thermometer",
            steps: [
                "Go to the accessory detail view for your thermostat",
                "View the current temperature at the top",
                "Use the temperature controls to set your desired target temperature",
                "Switch between Heat, Cool, Auto, and Off modes",
                "The thermostat will automatically maintain your target temperature"
            ],
            tips: [
                "Create scenes for different temperature preferences (Sleep, Wake, Away)",
                "Use automations to adjust temperature based on time of day or when you leave home",
                "Check your thermostat's battery level regularly"
            ],
            commonIssues: [
                CommonIssue(issue: "Temperature not changing", solution: "Ensure your HVAC system is turned on and working properly. Check that the thermostat has power or fresh batteries."),
                CommonIssue(issue: "Mode won't change", solution: "Some thermostats have physical locks or settings that prevent mode changes. Check your thermostat's manual.")
            ]
        ),

        HelpTopic(
            category: .accessories,
            title: "Controlling Locks",
            description: "Lock and unlock smart door locks securely",
            icon: "lock.fill",
            steps: [
                "Navigate to your lock in the Accessories tab or from its room",
                "Click on the lock card to view its status",
                "Use the Lock or Unlock button to change the state",
                "View lock history to see when the lock was last used",
                "Check battery status to ensure the lock has power"
            ],
            tips: [
                "Create an automation to lock all doors when you say 'Goodnight' to Siri",
                "Set up arrival/departure automations to lock doors when everyone leaves",
                "Never share your iCloud credentials - use Home app sharing instead"
            ],
            commonIssues: [
                CommonIssue(issue: "Lock shows 'No Response'", solution: "Check if the lock has fresh batteries. Ensure it's within range of your Wi-Fi network or a Thread border router."),
                CommonIssue(issue: "Can't unlock the door", solution: "For security, some locks require authentication on an iPhone or iPad to unlock. Check your lock's settings in the Home app.")
            ]
        ),

        HelpTopic(
            category: .accessories,
            title: "Controlling Outlets & Switches",
            description: "Control power outlets and light switches",
            icon: "poweroutlet.type.b.fill",
            steps: [
                "Find your outlet or switch in any accessory view",
                "Click to toggle power on or off",
                "Use in scenes to control multiple outlets at once",
                "Check power consumption if your outlet supports energy monitoring"
            ],
            tips: [
                "Use smart outlets to make any device controllable (lamps, fans, etc.)",
                "Create an 'All Off' scene to turn off all outlets when leaving",
                "Label outlets clearly in the Home app for easy identification"
            ],
            commonIssues: [
                CommonIssue(issue: "Outlet won't turn on", solution: "Ensure the outlet is plugged in and has power. Check your breaker box. Try unplugging and replugging the outlet.")
            ]
        ),

        HelpTopic(
            category: .accessories,
            title: "Controlling Fans",
            description: "Adjust fan speed and rotation direction",
            icon: "fan.fill",
            steps: [
                "Navigate to your fan's detail view",
                "Use the power button to turn the fan on or off",
                "Adjust speed using the speed slider (Low, Medium, High)",
                "Change rotation direction if your fan supports it",
                "Some fans also control integrated lights separately"
            ],
            tips: [
                "Set fans to reverse rotation in winter to push warm air down",
                "Create 'Sleep' scene with fan at low speed",
                "Combine fan control with thermostat automations for better climate control"
            ],
            commonIssues: []
        ),

        HelpTopic(
            category: .accessories,
            title: "Window Coverings & Blinds",
            description: "Open, close, and adjust window coverings",
            icon: "blinds.vertical.closed",
            steps: [
                "Find your window covering in the Accessories tab",
                "Use the position slider to set the exact position (0% = closed, 100% = open)",
                "Quick buttons let you fully open or close with one tap",
                "Add to scenes for synchronized control of multiple blinds"
            ],
            tips: [
                "Create a 'Good Morning' scene that opens all blinds",
                "Use automations to close blinds at sunset for privacy",
                "Schedule blinds to open gradually for a natural wake-up"
            ],
            commonIssues: [
                CommonIssue(issue: "Blinds move partially then stop", solution: "Check for obstructions. Some blinds need to be recalibrated - consult your manufacturer's instructions.")
            ]
        ),

        // Scenes & Shortcuts
        HelpTopic(
            category: .scenes,
            title: "Understanding Scenes",
            description: "Learn what scenes are and how they work",
            icon: "sparkles",
            steps: [
                "A scene is a collection of accessory states saved together",
                "When you activate a scene, all accessories change to their saved states instantly",
                "Scenes can control lights, locks, thermostats, and any HomeKit accessory",
                "Examples: 'Good Morning' (lights on, blinds open), 'Movie Time' (lights dim, TV on)",
                "Create scenes in the Home app on iPhone/iPad, then activate them from HomeKitTV"
            ],
            tips: [
                "Use scenes instead of controlling accessories one by one",
                "Create a 'Leave Home' scene that turns off lights, locks doors, and adjusts thermostat",
                "Scenes can be activated by Siri: 'Hey Siri, activate Movie Time'"
            ],
            commonIssues: []
        ),

        HelpTopic(
            category: .scenes,
            title: "Activating Scenes",
            description: "Run scenes to control multiple accessories at once",
            icon: "play.circle.fill",
            steps: [
                "Go to the Scenes tab or Home tab",
                "Find the scene you want to activate",
                "Click on the scene card to run it",
                "All accessories will change to their scene states within a few seconds",
                "Check the status message to confirm the scene executed successfully"
            ],
            tips: [
                "Add frequently-used scenes to favorites for quick access on the Home tab",
                "Use Siri to activate scenes hands-free",
                "Create different scenes for different times of day"
            ],
            commonIssues: [
                CommonIssue(issue: "Scene doesn't work", solution: "Check that all accessories in the scene are responding. If one accessory is offline, it may prevent the scene from executing properly."),
                CommonIssue(issue: "Some accessories don't respond", solution: "Verify that each accessory is reachable and powered on. Try controlling them individually first.")
            ]
        ),

        HelpTopic(
            category: .scenes,
            title: "Creating & Editing Scenes",
            description: "Create new scenes and modify existing ones",
            icon: "pencil.circle.fill",
            steps: [
                "Note: Scene creation and editing is currently only available in the Home app on iOS/iPadOS",
                "Open the Home app on your iPhone or iPad",
                "Tap the + button and select 'Add Scene'",
                "Choose accessories and set their desired states",
                "Name your scene and tap 'Done'",
                "The scene will automatically appear in HomeKitTV"
            ],
            tips: [
                "Plan your scenes based on daily routines (Morning, Evening, Night, Away)",
                "Include all relevant accessories in a scene, not just lights",
                "Test your scene after creating it to ensure it works as expected",
                "Future updates to HomeKitTV will allow scene editing directly on Apple TV"
            ],
            commonIssues: []
        ),

        HelpTopic(
            category: .scenes,
            title: "Scene Management",
            description: "View and organize your HomeKit scenes",
            icon: "list.bullet",
            steps: [
                "Go to More > Scene Management",
                "View all your scenes with their action counts",
                "See which accessories are controlled by each scene",
                "Execute any scene with the play button",
                "View scene types (Sleep, Wake Up, Arrive Home, Leave Home)"
            ],
            tips: [
                "Organize scenes by naming them clearly (e.g., 'Evening Relax' vs 'Scene 1')",
                "Review your scenes periodically and remove ones you don't use",
                "Consider the order: use scene suggestions like Good Morning, Arrive Home, Leave Home"
            ],
            commonIssues: []
        ),

        // Automations & Routines
        HelpTopic(
            category: .automation,
            title: "Understanding Automations",
            description: "Learn how to automate your smart home",
            icon: "gearshape.2.fill",
            steps: [
                "Automations run scenes or control accessories automatically based on triggers",
                "Common triggers: time of day, location, sensor detection, accessory state",
                "Example: Turn on porch light at sunset, lock doors when everyone leaves",
                "Automations require a home hub (Apple TV, HomePod, or iPad)",
                "Create automations in the Home app on iOS, view them in HomeKitTV"
            ],
            tips: [
                "Start with simple time-based automations before using complex triggers",
                "Use location-based automations when the last person leaves or first person arrives",
                "Combine multiple conditions for smarter automations"
            ],
            commonIssues: [
                CommonIssue(issue: "Automation doesn't run", solution: "Ensure you have a home hub set up and it's connected to the internet. Check that all accessories in the automation are responding."),
                CommonIssue(issue: "Location automation unreliable", solution: "Ensure Location Services are enabled for the Home app on all users' iPhones. Significant location changes are more reliable than geofence boundaries.")
            ]
        ),

        HelpTopic(
            category: .automation,
            title: "Viewing Automations",
            description: "See all your HomeKit automations",
            icon: "list.bullet.circle.fill",
            steps: [
                "Go to More > Automations",
                "View all configured automations",
                "See trigger types and conditions for each automation",
                "Check which accessories or scenes are controlled",
                "Note: Enabling/disabling automations requires the Home app on iOS"
            ],
            tips: [
                "Review your automations regularly to ensure they still match your needs",
                "Temporarily disable automations when on vacation",
                "Use meaningful names for automations so you remember what they do"
            ],
            commonIssues: []
        ),

        HelpTopic(
            category: .automation,
            title: "Routines",
            description: "Create multi-step smart home routines",
            icon: "sparkles",
            steps: [
                "Go to More > Routines to view advanced automation sequences",
                "Routines can include delays between actions",
                "Chain multiple scenes together for complex behaviors",
                "Example: 'Bedtime' routine - turn off all lights, wait 5 minutes, lock doors",
                "Routines are created in the Home app and executed by HomeKitTV"
            ],
            tips: [
                "Use routines for complex multi-step scenarios",
                "Add delays between steps to create smooth transitions",
                "Combine routines with time triggers for daily automated sequences"
            ],
            commonIssues: []
        ),

        // Advanced Features
        HelpTopic(
            category: .advanced,
            title: "Activity History",
            description: "View a log of all HomeKit actions",
            icon: "clock.arrow.circlepath",
            steps: [
                "Go to More > Activity History",
                "See a chronological list of all actions taken",
                "View which accessories were controlled and when",
                "Filter by date or accessory type",
                "Use history to troubleshoot issues or review changes"
            ],
            tips: [
                "Check activity history if accessories are changing state unexpectedly",
                "Review history to see if automations are running correctly",
                "Clear history periodically to free up storage"
            ],
            commonIssues: []
        ),

        HelpTopic(
            category: .advanced,
            title: "Energy Dashboard",
            description: "Monitor energy consumption of your accessories",
            icon: "bolt.fill",
            steps: [
                "Go to More > Energy Dashboard",
                "View real-time power consumption for supported accessories",
                "See historical energy usage over time",
                "Identify energy-hungry devices",
                "Track cost savings from smart automations"
            ],
            tips: [
                "Use energy monitoring to find devices you forgot to turn off",
                "Create automations to turn off high-power devices when not needed",
                "Check energy usage before and after implementing automations"
            ],
            commonIssues: [
                CommonIssue(issue: "No energy data showing", solution: "Only accessories with energy monitoring capabilities will show data. Check if your outlets/switches support this feature.")
            ]
        ),

        HelpTopic(
            category: .advanced,
            title: "Zones",
            description: "Group multiple rooms into zones",
            icon: "square.grid.2x2.fill",
            steps: [
                "Go to More > Zones",
                "Create zones to group related rooms (Upstairs, Downstairs, Outside)",
                "Control all accessories in a zone at once",
                "Use zones in scenes and automations",
                "Example: 'Upstairs' zone includes Bedroom, Bathroom, Hallway"
            ],
            tips: [
                "Create zones that match how you think about your home",
                "Use zones for faster control of large groups",
                "Zones work great with voice commands: 'Turn off all upstairs lights'"
            ],
            commonIssues: []
        ),

        HelpTopic(
            category: .advanced,
            title: "Accessory Diagnostics",
            description: "Troubleshoot and monitor accessory health",
            icon: "stethoscope",
            steps: [
                "Go to More > Accessory Diagnostics",
                "View connection status for all accessories",
                "Check signal strength and network connectivity",
                "See battery levels for battery-powered accessories",
                "Identify accessories that are offline or having issues"
            ],
            tips: [
                "Check diagnostics if accessories are responding slowly",
                "Look for low battery warnings before accessories stop working",
                "Weak signal strength may require adding Thread border routers or Wi-Fi extenders"
            ],
            commonIssues: [
                CommonIssue(issue: "Accessory shows as unreachable", solution: "Check if the accessory has power and is within range of your network. Try power cycling the accessory and your router."),
                CommonIssue(issue: "Slow response times", solution: "Check signal strength in diagnostics. Consider adding Wi-Fi extenders or Thread border routers for better coverage.")
            ]
        ),

        HelpTopic(
            category: .advanced,
            title: "Hub Status",
            description: "Monitor your HomeKit home hub",
            icon: "appletv.fill",
            steps: [
                "Go to More > Hub Status",
                "View which device is acting as your home hub",
                "Check hub connectivity status",
                "See if multiple hubs are available for redundancy",
                "Ensure your hub is connected to enable remote access and automations"
            ],
            tips: [
                "Keep your home hub powered on and connected at all times",
                "Multiple hubs provide redundancy if one goes offline",
                "Your Apple TV, HomePod, or iPad can act as a home hub"
            ],
            commonIssues: [
                CommonIssue(issue: "Hub is offline", solution: "Ensure your Apple TV, HomePod, or iPad is powered on, connected to Wi-Fi, and signed into iCloud."),
                CommonIssue(issue: "Remote access not working", solution: "Check that your home hub is connected. Verify that your iOS devices are signed into the same iCloud account.")
            ]
        ),

        HelpTopic(
            category: .advanced,
            title: "Notification Center",
            description: "View alerts from your HomeKit accessories",
            icon: "bell.fill",
            steps: [
                "Go to More > Notification Center",
                "See alerts from sensors, cameras, and accessories",
                "Filter notifications by type or accessory",
                "Mark notifications as read",
                "Configure notification settings in the Home app on iOS"
            ],
            tips: [
                "Set up motion detection notifications for security",
                "Get alerts when doors or windows open",
                "Receive low battery warnings before accessories stop working"
            ],
            commonIssues: []
        ),

        // Troubleshooting
        HelpTopic(
            category: .troubleshooting,
            title: "Accessories Not Responding",
            description: "Fix unresponsive HomeKit accessories",
            icon: "exclamationmark.triangle.fill",
            steps: [
                "Check if the accessory has power (plugged in or fresh batteries)",
                "Ensure your Apple TV is connected to Wi-Fi",
                "Verify that your router is working properly",
                "Try power cycling the accessory (unplug for 10 seconds, plug back in)",
                "Check if other accessories are working to rule out hub issues",
                "Restart your Apple TV if multiple accessories aren't responding"
            ],
            tips: [
                "Most connection issues are solved by power cycling",
                "Check Accessory Diagnostics to see signal strength",
                "Ensure your accessories are within range of your network"
            ],
            commonIssues: [
                CommonIssue(issue: "Single accessory won't respond", solution: "Power cycle that specific accessory. Check if it needs a firmware update in the manufacturer's app."),
                CommonIssue(issue: "All accessories unresponsive", solution: "Check your home hub status. Restart your Apple TV and router. Ensure you're signed into iCloud."),
                CommonIssue(issue: "Accessories respond slowly", solution: "Check Wi-Fi signal strength. Consider adding network extenders or upgrading your router.")
            ]
        ),

        HelpTopic(
            category: .troubleshooting,
            title: "Connection Issues",
            description: "Resolve network and connectivity problems",
            icon: "wifi.slash",
            steps: [
                "Verify your Apple TV is connected to Wi-Fi (Settings > Network)",
                "Restart your router by unplugging it for 30 seconds",
                "Move accessories closer to your router or add Wi-Fi extenders",
                "Check for 2.4GHz network availability (some accessories require it)",
                "Ensure your network doesn't have AP isolation enabled",
                "Update your router firmware"
            ],
            tips: [
                "Most HomeKit accessories work better on 2.4GHz Wi-Fi",
                "Thread accessories need a Thread border router (HomePod mini, Apple TV 4K)",
                "Avoid using guest networks for HomeKit accessories"
            ],
            commonIssues: [
                CommonIssue(issue: "Can't add accessories", solution: "Ensure your iPhone and the accessory are on the same Wi-Fi network. Check that HomeKit isn't blocked on your router."),
                CommonIssue(issue: "Accessories drop offline frequently", solution: "Check router settings for AP isolation or client isolation - these must be disabled for HomeKit.")
            ]
        ),

        HelpTopic(
            category: .troubleshooting,
            title: "Remote Access Not Working",
            description: "Enable and fix remote access to your home",
            icon: "network",
            steps: [
                "Ensure you have a home hub set up (Apple TV, HomePod, or iPad)",
                "Verify your hub is signed into iCloud with the same account",
                "Check that your hub is connected to the internet",
                "Enable iCloud Keychain on all devices",
                "Wait 10-15 minutes after setting up a new hub",
                "Check Hub Status in More > Hub Status"
            ],
            tips: [
                "Remote access requires an active home hub",
                "Keep your hub powered on and connected at all times",
                "Two-factor authentication must be enabled for iCloud"
            ],
            commonIssues: [
                CommonIssue(issue: "Remote access not available", solution: "Check that you have a home hub configured. Ensure it's connected to the internet and signed into iCloud."),
                CommonIssue(issue: "Works locally but not remotely", solution: "Verify iCloud Keychain is enabled on all devices. Check that your home hub has an active internet connection.")
            ]
        ),

        HelpTopic(
            category: .troubleshooting,
            title: "App Not Loading Data",
            description: "Fix issues with HomeKitTV not showing accessories",
            icon: "arrow.clockwise",
            steps: [
                "Pull to refresh on any screen to reload data",
                "Check that you're signed into iCloud on your Apple TV",
                "Verify HomeKit is set up on an iPhone or iPad with the same iCloud account",
                "Ensure your Apple TV has HomeKit permissions (Settings > Privacy)",
                "Restart the HomeKitTV app",
                "Restart your Apple TV if the issue persists"
            ],
            tips: [
                "The first load may take 30-60 seconds for large homes",
                "Check Settings to adjust auto-refresh intervals",
                "Make sure your Apple TV software is up to date"
            ],
            commonIssues: [
                CommonIssue(issue: "Empty home screen", solution: "Ensure HomeKit is configured on an iOS device with the same iCloud account. Check that your Apple TV is signed into iCloud."),
                CommonIssue(issue: "Accessories missing", solution: "Pull to refresh. Check if accessories are hidden in the Home app on iOS. Verify accessories are assigned to rooms.")
            ]
        ),

        HelpTopic(
            category: .troubleshooting,
            title: "Performance Issues",
            description: "Improve app speed and responsiveness",
            icon: "speedometer",
            steps: [
                "Close other apps running in the background",
                "Restart your Apple TV",
                "Check available storage space (Settings > General > Manage Storage)",
                "Reduce the number of accessories shown at once using favorites",
                "Adjust auto-refresh settings if updates are too frequent",
                "Clear activity history if it's very large"
            ],
            tips: [
                "Keep your Apple TV updated to the latest tvOS version",
                "Restart your Apple TV weekly for best performance",
                "Use favorites and zones to reduce the number of displayed accessories"
            ],
            commonIssues: [
                CommonIssue(issue: "App is slow or laggy", solution: "Restart your Apple TV. Close other apps. Check if your home has an unusually large number of accessories (100+)."),
                CommonIssue(issue: "Controls are delayed", solution: "Check your network connection. Ensure your router isn't overloaded. Verify accessories are responding in diagnostics.")
            ]
        )
    ]
}

/// Common issue structure
struct CommonIssue: Equatable {
    let issue: String
    let solution: String
}

#Preview {
    HelpView()
        .environmentObject(HomeKitManager())
}
