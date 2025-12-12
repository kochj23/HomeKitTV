# Apple TV Wake Setup Guide

This project includes an automatic pre-build script that attempts to wake up your physical Apple TVs before deployment.

## How It Works

When you build/run the HomeKitTV app in Xcode, the **"Wake Apple TV Devices"** build phase runs automatically before compilation. This script tries to wake up your Apple TVs so they're ready to receive the app deployment.

## Setup Instructions

### Option 1: Network Ping (Recommended)

1. **Find your Apple TV IP addresses**:
   - On each Apple TV: **Settings → Network → Wi-Fi → [Your Network]**
   - Note the IP address (e.g., `192.168.1.100`)

2. **Edit the build script in Xcode**:
   - Open HomeKitTV.xcodeproj in Xcode
   - Select the **HomeKitTV** project in the navigator
   - Select the **HomeKitTV** target
   - Go to **Build Phases** tab
   - Expand **"Wake Apple TV Devices"** (the first phase)
   - Find the configuration section in the script (around line 6)

3. **Add your IP addresses**:
   ```bash
   APPLETV_IPS=(
       "192.168.1.100"  # Living Room Apple TV
       "192.168.1.101"  # Bedroom Apple TV
   )
   ```
   Remove the `#` comments from the lines and replace with your actual IPs.

4. **Save** (Cmd+S) - that's it! The script will now ping your Apple TVs before each build.

### Option 2: HomeKit Shortcuts (Alternative)

If your Apple TVs are controlled via HomeKit, you can create a Shortcuts automation:

1. **Create a Shortcut in macOS Shortcuts app**:
   - Name it something like "Wake Apple TVs"
   - Add actions to turn on your Apple TVs via HomeKit

2. **Edit the build phase script in Xcode** (same location as above) and configure:
   ```bash
   USE_SHORTCUTS=true
   SHORTCUT_NAME="Wake Apple TVs"
   ```

## How to Test

Build the project and watch the build log. You should see output showing:
```
📺 Waking up physical Apple TV devices...
📡 Pinging Apple TVs...
  Pinging 192.168.1.100...
  ✅ 192.168.1.100 reachable
⏳ Waiting 3 seconds...
✅ Wake sequence complete
```

## Troubleshooting

### "No physical Apple TV devices detected in Xcode"

**Solution**: Make sure your Apple TVs are:
1. Connected to the **same network** as your Mac
2. **Paired in Xcode**: Window → Devices and Simulators → Add Device
3. Have **Remote Login enabled**: Settings → Remotes and Devices → Remote App and Devices

### Apple TVs still not waking up

**Possible causes**:
- Apple TVs are on a different network/VLAN
- Network firewall blocking pings
- Apple TVs are completely powered off (not just sleeping)

**Solutions**:
1. Use the HomeKit Shortcuts method instead (Option 2)
2. Manually wake your Apple TVs before building
3. Keep Apple TVs awake during development

## Build Phase Details

- **Name**: Wake Apple TV Devices
- **Location**: Project → Build Phases → Wake Apple TV Devices (runs first)
- **Script**: Embedded directly in the build phase (avoids sandbox restrictions)
- **When**: Runs before every build (pre-compilation)
- **Configuration**: Edit directly in Xcode Build Phases

## Disabling Auto-Wake

If you want to disable the automatic wake feature:

**Temporary (one build):**
- In Xcode, hold Option and click Product → Build Without Running

**Permanent:**
1. Open Xcode
2. Select HomeKitTV project → HomeKitTV target
3. Go to **Build Phases**
4. Find **"Wake Apple TV Devices"**
5. Uncheck the box next to the phase name or delete the build phase entirely

## Advanced: Wake Methods

The script tries two methods to wake your Apple TVs:

1. **Network Ping**: Sends ICMP ping packets (3 pings) to each configured IP
   - Pros: Simple, works for most sleeping Apple TVs
   - Cons: May not work if Apple TV is completely powered off or on different VLAN

2. **HomeKit Shortcuts**: Runs a macOS Shortcut that controls Apple TV via HomeKit
   - Pros: Can truly turn on Apple TVs even if powered off
   - Cons: Requires HomeKit setup and Shortcuts configuration

---

**Developed by**: Jordan Koch
**Configuration**: Edit in Xcode → Build Phases → Wake Apple TV Devices
**Documentation**: This file (`WAKE_APPLETV_SETUP.md`)
**Reference Script**: `/Volumes/Data/xcode/HomeKitTV/scripts/wake-appletv-devices.sh` (for reference only, not used by build)
