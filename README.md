# HomeKitTV v3.2.0

**Native tvOS application for controlling HomeKit smart home from Apple TV**

Control your entire smart home from the comfort of your couch with Apple TV remote gestures and a TV-optimized interface.

---

## What is HomeKitTV?

HomeKitTV is a comprehensive tvOS application that brings full HomeKit control to your Apple TV. Designed specifically for the big screen and Apple TV Siri Remote, it provides an intuitive card-based interface for managing lights, outlets, switches, thermostats, fans, locks, and all HomeKit accessories from your TV.

**Key Benefits:**
- **Big Screen Control**: View and control all HomeKit devices from TV
- **Apple TV Remote Optimized**: Swipe gestures for intuitive navigation
- **Room Organization**: Browse accessories by room for quick access
- **Scene Activation**: Execute HomeKit scenes with one click
- **Real-Time Updates**: Live status updates for all accessories
- **TV-Optimized UI**: Large cards and text readable from 10+ feet away

**Perfect For:**
- **Smart Home Owners**: Central control point in living room
- **Accessibility**: Easier than phone for some users
- **Guests**: Simple interface for visitors
- **Automation**: Quick scene activation from couch

---

## What's New in v3.2.0 (January 2026)

### 📱 Enhanced Apple TV Remote Control
**Full swipe gesture support for intuitive navigation:**

- **Swipe Up**: Scroll up through lists and accessories
- **Swipe Down**: Scroll down through content
- **Swipe Left**: Navigate back or previous item
- **Swipe Right**: Navigate forward or next item
- **Notification-Based**: App-wide gesture handling via NotificationCenter
- **Memory Safe**: Proper observer cleanup prevents crashes

**Technical Implementation:**
```swift
// RemoteControlManager.swift
func handleSwipeGesture(_ direction: SwipeDirection) {
    switch direction {
    case .up:
        NotificationCenter.default.post(name: .scrollUp, object: nil)
    case .down:
        NotificationCenter.default.post(name: .scrollDown, object: nil)
    case .left:
        NotificationCenter.default.post(name: .navigateBack, object: nil)
    case .right:
        NotificationCenter.default.post(name: .navigateForward, object: nil)
    }
}
```

---

## Features

### Core Functionality
- **Full HomeKit Integration**: Control all HomeKit accessories from Apple TV
- **Four Main Sections**: Home overview, Rooms, Scenes, All Accessories
- **Tab Navigation**: Easy switching between main views
- **Card-Based UI**: Large cards optimized for TV viewing from distance
- **Real-Time Status**: Live updates for all accessory states
- **Apple TV Remote Support (v3.2.0)**: Full swipe gesture navigation

### Home View
- **Primary Home Display**: Shows active HomeKit home name
- **Favorite Scenes**: Quick access to first 6 favorite scenes
- **Room Overview**: Cards showing all rooms with accessory counts
- **Adaptive Grid**: Responsive layout for different screen sizes

### Rooms View
- **Room Grid**: All rooms displayed as navigable cards
- **Accessory Counts**: Shows number of accessories per room
- **Room Navigation**: Drill down to room details
- **Room-Specific Controls**: Control all accessories in a room

### Scenes View
- **All Configured Scenes**: Every HomeKit scene available
- **One-Tap Activation**: Execute scenes with single click
- **Visual Scene Cards**: Iconography for quick identification
- **Grid Layout**: Optimized for TV browsing

### Accessories View
- **Complete Accessory List**: All HomeKit accessories in one view
- **Type Sorting**: Organized by accessory type (lights, switches, etc.)
- **Detail Navigation**: Tap for detailed controls
- **Card Presentation**: Consistent UI throughout

### Accessory Controls
- **Power Control**: On/off toggle for lights, outlets, switches
- **Brightness Control**: Slider interface for dimmable lights
- **Color Control**: HSB color picker for color bulbs
- **Thermostat Control**: Temperature adjustment, mode selection
- **Fan Control**: Speed control, oscillation toggle
- **Lock Control**: Lock/unlock with confirmation dialogs
- **Window Covering**: Position control for blinds/shades
- **Service-Specific**: Dedicated controls for each accessory type

### Navigation & Gestures (v3.2.0)
- **Swipe Up/Down**: Scroll through lists
- **Swipe Left/Right**: Navigate back/forward
- **Click to Select**: Standard Siri Remote click
- **Menu Button**: Navigate back one level
- **Home Button**: Return to tvOS home screen

---

## Security

### HomeKit Security
- **Encrypted Communication**: All HomeKit traffic encrypted end-to-end
- **iCloud Keychain**: Credentials stored securely by HomeKit framework
- **Same Network**: Accessories must be on same network as Apple TV
- **Authentication**: Requires same iCloud account as iOS device with Home app

### Privacy
- **No External Services**: All control happens locally via HomeKit
- **No Cloud Dependencies**: Direct accessory communication
- **No Telemetry**: Zero analytics or tracking
- **Local Processing**: Everything stays on your network

### Best Practices
- Ensure Apple TV and accessories on secure Wi-Fi network
- Use strong Wi-Fi password (WPA3 preferred)
- Keep Apple TV software updated
- Verify all accessories have latest firmware
- Use HomeKit Secure Video for cameras

---

## Requirements

### Hardware Requirements
- **Apple TV 4K** (1st gen or later) OR
- **Apple TV HD** (4th generation)
- **HomeKit Accessories**: At least one HomeKit-compatible device
- **Wi-Fi Network**: Apple TV and accessories on same network

### Software Requirements
- **tvOS 14.0 or later** (tvOS 14, 15, 16, 17, 18 beta)
- **iOS Device**: iPhone or iPad with Home app for initial setup
- **iCloud Account**: Same account on Apple TV and iOS device
- **Home App**: Accessories configured in iOS Home app

### Network Requirements
- **Local Network Access**: Apple TV must reach accessories
- **Internet**: Not required for basic control (needed for remote access)
- **Router**: Support for mDNS/Bonjour for accessory discovery

### Development Requirements
- **Xcode 15.0+** (for building from source)
- **macOS 13.0+** (Ventura or later for Xcode)
- **tvOS 14.0+ SDK**

---

## Installation

### Option 1: Sideload to Apple TV

1. **Connect Apple TV** to Mac via USB-C
2. **Open Xcode** and select Window → Devices and Simulators
3. **Select your Apple TV** in device list
4. **Click "+"** to add app
5. **Select** built .app bundle
6. **Wait for installation** to complete
7. **Launch** from Apple TV home screen

### Option 2: Build and Deploy

1. **Clone Repository:**
   ```bash
   git clone https://github.com/kochj23/HomeKitTV.git
   cd HomeKitTV
   ```

2. **Open in Xcode:**
   ```bash
   open "HomeKitTV.xcodeproj"
   ```

3. **Select Apple TV:**
   - Choose your Apple TV from device list
   - Or select tvOS Simulator

4. **Build and Run:**
   - Press ⌘R to build and deploy
   - App automatically launches on Apple TV

### Option 3: TestFlight (If Configured)

1. Install TestFlight on Apple TV
2. Accept invitation
3. Install HomeKitTV
4. Launch from home screen

---

## Configuration

### Prerequisites

1. **Set up HomeKit** on iPhone/iPad using Home app:
   - Add accessories
   - Organize into rooms
   - Create scenes
   - Configure automations

2. **Ensure Apple TV** is signed in to same iCloud account

3. **Verify Network**: Apple TV and accessories on same Wi-Fi

### First Launch

1. **Launch HomeKitTV** from Apple TV home screen

2. **Grant Permissions**:
   - HomeKit access permission
   - Local network access

3. **Wait for Discovery**:
   - App automatically discovers HomeKit homes
   - Loads all accessories, rooms, scenes

4. **Navigate**:
   - Use Siri Remote to browse tabs
   - Swipe gestures (v3.2.0) for smooth navigation
   - Click on accessories to control

### Customization

**HomeKit Configuration** (via iOS Home app):
- Assign accessories to rooms
- Create custom scenes
- Set favorite scenes (appear first in HomeKitTV)
- Name accessories clearly (names appear on TV)

**Apple TV Settings:**
- Display settings for text size
- Reduce motion if needed
- VoiceOver for accessibility

---

## Usage

### Basic Operation

**Launch App:**
- Navigate to HomeKitTV icon on Apple TV home screen
- Click to open

**Main Navigation:**
- **Home Tab**: Overview with favorite scenes and rooms
- **Rooms Tab**: Browse by room
- **Scenes Tab**: Execute scenes
- **Accessories Tab**: All devices listed

### Controlling Accessories

**Turn On/Off:**
1. Navigate to accessory card
2. Click to toggle power
3. Status updates immediately

**Adjust Brightness:**
1. Select light accessory
2. Navigate to detail view
3. Use slider to adjust
4. Changes apply in real-time

**Control Thermostat:**
1. Select thermostat
2. Adjust temperature with +/- controls
3. Change mode (heat/cool/auto)
4. View current temperature

**Activate Scene:**
1. Go to Scenes tab
2. Select scene card
3. Click to activate
4. All accessories execute scene

### Apple TV Remote Gestures (v3.2.0)

**Scrolling:**
- Swipe Up: Scroll up through content
- Swipe Down: Scroll down through lists

**Navigation:**
- Swipe Left: Go back to previous screen
- Swipe Right: Go forward (if applicable)
- Click: Select item
- Menu Button: Go back one level

**Tips:**
- Swipe gestures work throughout entire app
- Smooth scrolling for long accessory lists
- Consistent behavior across all views

---

## Troubleshooting

### Common Issues

**No Accessories Showing:**
- Verify HomeKit setup in iOS Home app
- Check Apple TV signed into same iCloud account
- Ensure Apple TV and accessories on same network
- Restart HomeKitTV app
- Restart Apple TV if persistent

**Can't Control Accessories:**
- Check accessory is responding in iOS Home app
- Verify network connectivity
- Check HomeKit permission granted to app
- Try resetting accessory
- Check accessory firmware is up to date

**Swipe Gestures Not Working (v3.2.0):**
- Verify using Siri Remote (2nd gen or later recommended)
- Check tvOS 14.0+ installed
- Try clicking item first, then swiping
- Restart app if gestures stop responding

**App Crashes on Launch:**
- Check tvOS version (14.0+ required)
- Verify iCloud account signed in
- Try deleting and reinstalling app
- Check Console logs via Xcode

**Slow Performance:**
- Reduce number of accessories (HomeKit limit ~150)
- Check network latency to accessories
- Restart Apple TV
- Update tvOS to latest version

**Can't Find Apple TV in Xcode:**
- Connect via USB-C cable
- Enable Developer Mode on Apple TV (Settings → Remotes and Devices → Remote App and Devices)
- Pair Apple TV with Xcode (Window → Devices and Simulators)

---

## Architecture

### Project Structure

```
HomeKitTV/
├── Models/
│   ├── HomeKitManager.swift         # HomeKit framework integration
│   ├── RemoteControlManager.swift   # Gesture handling (v3.2.0)
│   ├── NotificationSystem.swift     # System notifications
│   └── SettingsManager.swift        # App settings
├── Views/
│   ├── MainTabView.swift            # Tab navigation
│   ├── HomeView.swift               # Home overview
│   ├── RoomsView.swift              # Room grid
│   ├── ScenesView.swift             # Scene list
│   ├── AccessoriesView.swift        # All accessories
│   ├── DetailViews.swift            # Accessory details
│   ├── EnhancedControls.swift       # Service controls (thermostat, fan, etc.)
│   ├── AccessoryCard.swift          # Card UI component
│   └── LoadingView.swift            # Loading states
├── HomeKitTVApp.swift               # App entry point
├── Info.plist                       # App configuration
└── Entitlements.plist               # HomeKit capabilities
```

### Key Components

**HomeKitManager:**
- Manages HMHomeManager lifecycle
- Handles accessory discovery
- Processes state updates
- Controls accessories

**RemoteControlManager (v3.2.0):**
- Gesture event handling
- NotificationCenter integration
- Memory-safe observer cleanup

**EnhancedControls:**
- ThermostatControlView
- ColorControlView
- FanControlView
- LockControlView
- WindowCoveringControlView

---

## Development

### Building from Source

```bash
cd "/Volumes/Data/xcode/HomeKitTV"
xcodebuild -project "HomeKitTV.xcodeproj" -scheme "HomeKitTV" -configuration Release -destination 'generic/platform=tvOS' build
```

### Testing on Simulator

```bash
xcodebuild -project "HomeKitTV.xcodeproj" -scheme "HomeKitTV" -destination 'platform=tvOS Simulator,name=Apple TV' test
```

### Deployment

```bash
# Archive for distribution
xcodebuild archive -project "HomeKitTV.xcodeproj" -scheme "HomeKitTV" -archivePath "build/HomeKitTV.xcarchive"

# Sideload to Apple TV via Xcode Devices window
```

---

## Version History

### v3.2.0 (January 2026) - Current
- **Apple TV Remote Gestures**: Full swipe gesture support (up/down/left/right)
- **Notification-Based Navigation**: App-wide gesture handling
- **Memory Safety**: Proper NotificationCenter observer cleanup
- **Improved Scrolling**: Smooth navigation through long lists

### v3.1.0 (2025)
- **Enhanced Controls**: Thermostat, fan, lock, window covering controls
- **Color Control**: HSB color picker for color bulbs
- **Scene Grid**: Improved scene layout
- **Performance**: Faster accessory loading

### v3.0.0 (2025)
- **Initial Release**: Full HomeKit control from tvOS
- **Tab Navigation**: Home, Rooms, Scenes, Accessories
- **Basic Controls**: Power, brightness for common accessories
- **Card UI**: TV-optimized interface

---

## License

MIT License

Copyright © 2026 Jordan Koch

---

## Credits

- **Author**: Jordan Koch
- **Framework**: SwiftUI, HomeKit, tvOS
- **Platform**: tvOS 14.0+
- **Language**: Swift 5

---

## Support

**GitHub**: https://github.com/kochj23/HomeKitTV

**For Issues:**
- Verify HomeKit setup in iOS Home app first
- Check network connectivity
- Review Console logs via Xcode
- Ensure tvOS 14.0+ installed

---

**Last Updated:** January 27, 2026
**Version:** 3.2.0 (build 320)
**Status:** ✅ Production Ready
