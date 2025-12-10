#!/bin/bash

#
# Screenshot Capture Script for HomeKitTV App Store Submission
# Captures screenshots from Office Apple TV at 1920x1080 resolution
#

DEVICE_ID="915604CB-97FF-5F2E-9AE6-15AEB8852719"
OUTPUT_DIR="$HOME/Desktop/HomeKitTV-Screenshots"
APP_BUNDLE="com.kochj.HomeKitTV"

echo "📸 HomeKitTV Screenshot Capture Script"
echo "======================================="
echo ""
echo "Device: Office Apple TV"
echo "Output: $OUTPUT_DIR"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

echo "✅ Output directory created: $OUTPUT_DIR"
echo ""

# Launch the app first
echo "🚀 Launching HomeKitTV on Apple TV..."
xcrun devicectl device process launch --device "$DEVICE_ID" "$APP_BUNDLE" 2>&1 | grep -i "launched" || echo "App already running or launch failed"
echo ""

# Wait for app to launch
echo "⏳ Waiting 5 seconds for app to fully launch..."
sleep 5

echo ""
echo "📸 Ready to capture screenshots!"
echo ""
echo "Instructions:"
echo "1. Navigate to the screen you want to capture on your Apple TV"
echo "2. Press ENTER to capture"
echo "3. Repeat for each screen"
echo "4. Press Ctrl+C when done"
echo ""
echo "Recommended screenshots:"
echo "  1. Home screen (main view)"
echo "  2. Rooms view (device list)"
echo "  3. Scenes tab (available scenes)"
echo "  4. Scene activation (status overlay)"
echo "  5. Accessory control (brightness slider)"
echo "  6. Settings/More tab"
echo ""
echo "======================================="
echo ""

SCREENSHOT_NUM=1

while true; do
    read -p "Press ENTER to capture screenshot $SCREENSHOT_NUM (or Ctrl+C to quit): "

    FILENAME="HomeKitTV-Screenshot-$SCREENSHOT_NUM.png"

    echo "📸 Capturing screenshot $SCREENSHOT_NUM..."

    xcrun devicectl device screenshot \
        --device "$DEVICE_ID" \
        --output "$FILENAME" 2>&1 | grep -v "Acquired\|Enabling" || echo "Capture may have failed"

    if [ -f "$FILENAME" ]; then
        # Check resolution
        SIZE=$(sips -g pixelWidth -g pixelHeight "$FILENAME" 2>/dev/null | grep "pixel" | awk '{print $2}' | tr '\n' 'x' | sed 's/x$//')
        FILE_SIZE=$(ls -lh "$FILENAME" | awk '{print $5}')

        echo "✅ Captured: $FILENAME"
        echo "   Resolution: $SIZE"
        echo "   Size: $FILE_SIZE"

        # Resize to App Store requirements if needed (1920x1080)
        if [ "$SIZE" != "1920x1080" ]; then
            echo "   ⚠️  Resizing to 1920x1080 for App Store..."
            sips -z 1080 1920 "$FILENAME" --out "Resized-$FILENAME" >/dev/null 2>&1
            echo "   ✅ Created: Resized-$FILENAME"
        fi

        SCREENSHOT_NUM=$((SCREENSHOT_NUM + 1))
    else
        echo "❌ Failed to capture screenshot"
    fi

    echo ""
done

echo ""
echo "📸 Screenshot capture complete!"
echo "📁 Screenshots saved to: $OUTPUT_DIR"
echo ""
echo "Next steps:"
echo "1. Review screenshots for quality"
echo "2. Select your best 3-6 screenshots"
echo "3. Upload to App Store Connect"
echo ""
