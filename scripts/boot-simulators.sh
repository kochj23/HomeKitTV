#!/bin/bash

# boot-simulators.sh
# Automatically boots Apple TV simulators before deployment

echo "🚀 Booting Apple TV simulators..."

# Get all Apple TV simulator UDIDs
SIMULATOR_UDIDS=$(xcrun simctl list devices available | grep "Apple TV" | grep -E "\(Shutdown\)" | grep -oE "\([A-F0-9-]{36}\)" | tr -d "()")

if [ -z "$SIMULATOR_UDIDS" ]; then
    echo "✅ All Apple TV simulators are already booted or none available"
    exit 0
fi

# Boot each shutdown simulator
echo "Found shutdown simulators, booting..."
for UDID in $SIMULATOR_UDIDS; do
    DEVICE_NAME=$(xcrun simctl list devices | grep "$UDID" | sed 's/ (.*//')
    echo "  ⏳ Booting: $DEVICE_NAME ($UDID)"
    xcrun simctl boot "$UDID" 2>/dev/null

    if [ $? -eq 0 ]; then
        echo "  ✅ Booted successfully"
    else
        echo "  ⚠️  Already booting or error occurred"
    fi
done

echo "✅ All Apple TV simulators ready"
exit 0
