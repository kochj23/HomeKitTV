#!/bin/bash

# wake-appletv-devices.sh
# Wakes up physical Apple TV devices before deployment
#
# CONFIGURATION:
# Edit the APPLETV_IPS array below with your Apple TV IP addresses
# Or configure a Shortcuts automation to wake them via HomeKit

echo "📺 Waking up physical Apple TV devices..."

# ====================
# CONFIGURATION SECTION - Edit these values for your setup
# ====================

# Method 1: Apple TV IP Addresses
# Find your Apple TV IPs in Settings > Network on each device
APPLETV_IPS=(
    # "192.168.1.100"  # Example: Living Room Apple TV
    # "192.168.1.101"  # Example: Bedroom Apple TV
)

# Method 2: macOS Shortcuts (if you have HomeKit shortcuts configured)
USE_SHORTCUTS=false
SHORTCUT_NAME=""  # Example: "Wake Apple TVs"

# ====================
# END CONFIGURATION
# ====================

# Try Shortcuts first if configured
if [ "$USE_SHORTCUTS" = true ] && [ -n "$SHORTCUT_NAME" ]; then
    echo "🏠 Attempting to wake via Shortcuts: $SHORTCUT_NAME"
    if command -v shortcuts &> /dev/null; then
        shortcuts run "$SHORTCUT_NAME" 2>&1 | grep -v "^$"
        if [ $? -eq 0 ]; then
            echo "  ✅ Shortcut executed"
        else
            echo "  ⚠️  Shortcut failed or not found"
        fi
    else
        echo "  ⚠️  shortcuts command not available"
    fi
fi

# Try network ping to wake devices
if [ ${#APPLETV_IPS[@]} -gt 0 ]; then
    echo "📡 Attempting to wake Apple TVs via network ping..."
    for IP in "${APPLETV_IPS[@]}"; do
        # Skip commented lines
        if [[ "$IP" == \#* ]]; then
            continue
        fi

        echo "  Pinging $IP..."
        # Send multiple pings to help wake the device
        ping -c 3 -W 1 "$IP" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "  ✅ $IP is reachable"
        else
            echo "  ⚠️  $IP is not responding (might be sleeping or offline)"
        fi
    done

    # Give devices time to wake up
    echo "⏳ Waiting 3 seconds for devices to wake..."
    sleep 3
else
    echo "ℹ️  No Apple TV IPs configured"
    echo "ℹ️  To configure: edit $0 and add your Apple TV IP addresses"
fi

# Check for physical devices in Xcode
echo "🔍 Checking for Apple TV devices in Xcode..."
PHYSICAL_DEVICES=$(instruments -s devices 2>&1 | grep -i "apple tv" | grep -v "Simulator" || true)

if [ -n "$PHYSICAL_DEVICES" ]; then
    echo "✅ Found physical Apple TV devices:"
    echo "$PHYSICAL_DEVICES" | sed 's/^/  /'
else
    echo "⚠️  No physical Apple TV devices detected in Xcode"
    echo "ℹ️  Make sure your Apple TVs are:"
    echo "    - Connected to the same network as this Mac"
    echo "    - Paired in Xcode (Window > Devices and Simulators)"
    echo "    - Have Remote Login enabled (Settings > Remotes and Devices > Remote App and Devices)"
fi

echo "✅ Wake sequence complete"
exit 0
