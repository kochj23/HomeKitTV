# HomeKitTV v3.2.0

A native tvOS application for controlling HomeKit smart home devices from Apple TV, optimized for TV remote navigation.

## 🆕 What's New in v3.2.0 (January 2026)

### Enhanced Apple TV Remote Control
**Full swipe gesture support for intuitive navigation:**

- **Swipe Up** - Scroll up in current view (notification system integration)
- **Swipe Down** - Scroll down through accessories and rooms
- **Swipe Left** - Navigate back or previous item
- **Swipe Right** - Navigate forward or next item
- **Notification-Based** - Uses NotificationCenter for app-wide gesture handling
- **Memory Safe** - Proper observer cleanup to prevent crashes

**Usage:**
- Natural swipe gestures on Apple TV remote
- Consistent behavior across all app views
- Ideal for navigating long lists of accessories

## Description

HomeKitTV is a comprehensive tvOS application that brings full HomeKit control to your Apple TV. Designed specifically for the big screen and Apple TV remote, it provides an intuitive card-based interface for managing lights, outlets, switches, thermostats, fans, and other HomeKit accessories. The app features four main sections: Home overview, Rooms, Scenes, and All Accessories, with dedicated detail views for advanced controls like brightness adjustment.

## Platform

- **Platform:** tvOS
- **Minimum Version:** tvOS 14.0 or later
- **Language:** Swift 5
- **Framework:** SwiftUI, HomeKit

## Features

### Core Features
- Full HomeKit integration with Apple TV
- Tab-based navigation (Home, Rooms, Scenes, Accessories)
- Card-based UI optimized for TV viewing from distance
- Power control for lights, outlets, and switches
- Brightness control with slider interface
- Scene execution with one click
- Room-based accessory organization
- Real-time status updates
- Loading states and empty state guidance

### Home View
- Primary home name display
- Favorite scenes quick access (first 6)
- Room overview cards with accessory counts
- Adaptive grid layout

### Rooms View
- Grid of all rooms in the home
- Accessory count per room
- Navigation to room detail views
- Room-specific accessory control

### Scenes View
- All configured HomeKit scenes
- One-tap scene activation
- Visual scene cards
- Grid layout optimized for TV

### Accessories View
- Complete list of all HomeKit accessories
- Navigation to detailed accessory controls
- Sorted by accessory type
- Card-based presentation

### Detail Views
- Accessory detail with all services
- Brightness control for lights
- Service-specific controls
- Real-time characteristic updates

## Requirements

- Xcode 26.0.1 or later
- tvOS 14.0 SDK or later
- Swift 5 compiler
- Apple TV 4K or Apple TV HD
- HomeKit accessories configured in Home app
- Same iCloud account as iOS device with HomeKit setup

## Installation

### Prerequisites

1. Set up HomeKit accessories using iPhone/iPad Home app
2. Ensure Apple TV is signed in to the same iCloud account
3. HomeKit accessories must be on the same network as Apple TV

### Building from Source

1. Clone or download the repository
2. Open `HomeKitTV.xcodeproj` in Xcode
3. Select tvOS simulator or Apple TV device
4. Build the project using `Product > Build` (⌘B)
5. Run the application using `Product > Run` (⌘R)

### Deployment to Apple TV

1. Connect Apple TV to Mac via USB-C (Apple TV 4K 1st/2nd gen) or network
2. Enable Remote Login on Apple TV (Settings > Remotes and Devices > Remote App and Devices)
3. Select Apple TV as destination in Xcode
4. Build and run from Xcode

## Usage

### Navigation

Use the Apple TV remote (Siri Remote) to navigate:
- **Swipe:** Navigate between cards and tabs
- **Click:** Select items and toggle switches
- **Menu Button:** Go back to previous screen
- **TV/Home Button:** Exit to tvOS home screen

### Controlling Accessories

1. Select the appropriate tab (Home, Rooms, Scenes, or Accessories)
2. Navigate to the desired accessory or scene
3. Click to toggle power or execute scene
4. For lights, navigate to the accessory to access brightness controls

### Brightness Control

1. Navigate to Accessories tab
2. Select a light accessory
3. Use the brightness slider to adjust light level
4. Click to confirm or swipe to navigate

### Executing Scenes

1. Go to the Scenes tab
2. Select a scene card
3. Click to execute the scene
4. Status message appears confirming execution

## Architecture

### Project Structure

```
HomeKitTV/
├── HomeKitTVApp.swift           # App entry point
├── ContentView.swift            # Tab navigation and main views
├── HomeKitManager.swift         # HomeKit manager and state
├── Views/
│   ├── Cards.swift              # Reusable card components
│   └── DetailViews.swift        # Accessory and room details
└── Info.plist                   # HomeKit configuration
```

### Key Components

#### HomeKitManager
ObservableObject managing all HomeKit state:
- `primaryHome`: Primary HMHome object
- `rooms`: Array of HMRoom objects
- `accessories`: Array of HMAccessory objects
- `scenes`: Array of HMActionSet objects
- `isAuthorized`: HomeKit authorization status
- `isLoading`: Loading state indicator
- `statusMessage`: User feedback messages
- Implements HMHomeManagerDelegate

#### View Hierarchy
```
TabView (ContentView)
├── HomeView
│   ├── SceneCard
│   └── RoomCard
├── RoomsView
│   ├── RoomCard
│   └── RoomDetailView → AccessoryCard
├── ScenesView
│   └── SceneCard
└── AccessoriesView
    ├── AccessoryCard
    └── AccessoryDetailView
```

#### Card Components (Cards.swift)
- **AccessoryCard:** Display accessory with power toggle
- **RoomCard:** Display room with accessory count
- **SceneCard:** Display and execute scenes

#### Detail Views (DetailViews.swift)
- **AccessoryDetailView:** Detailed accessory controls
- **RoomDetailView:** All accessories in a room
- **BrightnessControl:** Slider for light brightness

### HomeKit Integration

```swift
class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    func loadHomeData()
    func toggleAccessory(_ accessory: HMAccessory)
    func executeScene(_ scene: HMActionSet)
    func setBrightness(_ accessory: HMAccessory, brightness: Int)
}
```

The manager uses HMHomeManager to access HomeKit data and delegates for real-time updates when accessories change state.

## Configuration

### Info.plist Requirements

```xml
<key>NSHomeKitUsageDescription</key>
<string>This app needs access to HomeKit to control your home accessories</string>

<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>homekit</string>
</array>

<key>UIStatusBarHidden</key>
<false/>
```

### Entitlements

The app requires HomeKit entitlement:
1. Target Settings > Signing & Capabilities
2. Add HomeKit capability
3. Ensure proper provisioning profile

### Bundle Configuration

- **Bundle ID:** Matches iOS Home app for shared HomeKit data
- **Version:** 1.0
- **Deployment Target:** tvOS 14.0

## Building

### Debug Build
```bash
xcodebuild -project "HomeKitTV.xcodeproj" -scheme HomeKitTV -configuration Debug -sdk appletvos
```

### Release Build
```bash
xcodebuild -project "HomeKitTV.xcodeproj" -scheme HomeKitTV -configuration Release -sdk appletvos
```

### Archive for TestFlight
```bash
xcodebuild archive -project "HomeKitTV.xcodeproj" -scheme HomeKitTV -archivePath HomeKitTV.xcarchive
```

## Troubleshooting

### No Accessories Found
- Verify HomeKit is set up on iPhone/iPad
- Ensure Apple TV uses same iCloud account
- Check network connectivity
- Restart Home Hub (iPad, HomePod, or Apple TV)
- Force quit and restart HomeKitTV app

### "HomeKit Not Available" Message
- Sign in to iCloud on Apple TV
- Enable HomeKit on iOS device
- Check that Home app works on iOS
- Verify Apple TV is designated as Home Hub (Settings > Users and Accounts > iCloud)

### Accessories Not Responding
- Check if accessories respond in iOS Home app
- Verify accessories are online and powered
- Restart HomeKit accessories
- Check Wi-Fi/network connectivity
- Look for firmware updates for accessories

### Brightness Control Not Working
- Ensure accessory supports brightness
- Check if brightness works in iOS Home app
- Verify accessory has brightness characteristic
- Try toggling power off and on

### Scenes Not Executing
- Verify scene exists in iOS Home app
- Check that all accessories in scene are online
- Review scene configuration
- Status message will show error details

### Remote Navigation Issues
- Ensure focus is properly set
- Try clicking the Menu button to reset
- Swipe deliberately between items
- Check Accessibility settings on Apple TV

### Performance Issues
- Reduce number of accessories
- Simplify scenes
- Check network speed
- Restart Apple TV
- Update tvOS to latest version

## Supported Accessories

The app supports all HomeKit-compatible accessories:
- **Lights:** On/off, brightness control
- **Outlets:** On/off control
- **Switches:** On/off control
- **Thermostats:** Temperature display (control coming soon)
- **Fans:** On/off, speed control
- **Locks:** Status display
- **Sensors:** Status display
- **Garage Doors:** Status and control
- **Window Coverings:** Position control

## TV Remote Optimization

The interface is specifically designed for Apple TV remote:
- Large touch targets (400x300pt cards)
- Focus-driven navigation
- Clear visual focus indicators
- Readable text from 10+ feet away
- Simplified controls for TV use
- Grid layouts optimized for remote swiping

## Security & Privacy

- All HomeKit communication is encrypted
- No data leaves the local network
- No cloud services or external servers
- Requires iCloud for HomeKit sync
- Data shared only within Apple ecosystem
- User authorization required

## Known Limitations

- Simulator has limited HomeKit functionality
- Some advanced accessory controls pending
- Requires iOS device for initial HomeKit setup
- Apple TV must be on same network as accessories
- Custom characteristics may not display

## License

Copyright (c) 2025 Jordan Koch

## Version History

- **Version 1.0** (2025)
  - Initial release
  - Four-tab interface (Home, Rooms, Scenes, Accessories)
  - Card-based UI optimized for tvOS
  - Power control for lights, outlets, switches
  - Brightness control for lights
  - Scene execution
  - Room organization
  - Detail views for accessories and rooms
  - Real-time status updates
  - Loading and empty states

---

**Last Updated:** January 22, 2026
**Status:** ✅ Production Ready
