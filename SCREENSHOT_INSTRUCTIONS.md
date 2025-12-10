# HomeKitTV Screenshot Capture Instructions

## Quick Commands for 6 Required Screenshots

**Prerequisites:**
1. Turn on your Office Apple TV
2. Navigate to HomeKitTV app
3. Keep your Mac terminal open

## Screenshot Capture Commands

### Screenshot 1: Home/Accessories Screen (Main View)
**What to show**: Main screen with your HomeKit accessories displayed

```bash
# Navigate to: Main Home/Accessories tab on TV
xcrun devicectl device screenshot capture --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 ~/Desktop/HomeKitTV-Screenshots/1-Home-Screen.png
```

### Screenshot 2: Rooms View
**What to show**: Devices organized by room

```bash
# Navigate to: Rooms tab on TV
xcrun devicectl device screenshot capture --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 ~/Desktop/HomeKitTV-Screenshots/2-Rooms-View.png
```

### Screenshot 3: Scenes Tab
**What to show**: List of available HomeKit scenes

```bash
# Navigate to: Scenes tab on TV
xcrun devicectl device screenshot capture --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 ~/Desktop/HomeKitTV-Screenshots/3-Scenes-List.png
```

### Screenshot 4: Scene Activation
**What to show**: Status overlay showing scene execution

```bash
# Navigate to: Scenes tab, activate a scene on TV (status will appear)
xcrun devicectl device screenshot capture --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 ~/Desktop/HomeKitTV-Screenshots/4-Scene-Activation.png
```

### Screenshot 5: Device Control Detail
**What to show**: Detail view of a light with brightness control

```bash
# Navigate to: Select a light accessory, show brightness slider on TV
xcrun devicectl device screenshot capture --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 ~/Desktop/HomeKitTV-Screenshots/5-Device-Control.png
```

### Screenshot 6: More/Settings Tab
**What to show**: Settings and additional options

```bash
# Navigate to: More tab on TV
xcrun devicectl device screenshot capture --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 ~/Desktop/HomeKitTV-Screenshots/6-More-Settings.png
```

## All-in-One Script

Or copy these commands to a file and run them one by one:

```bash
#!/bin/bash
DEVICE="915604CB-97FF-5F2E-9AE6-15AEB8852719"
OUTPUT="~/Desktop/HomeKitTV-Screenshots"

mkdir -p "$OUTPUT"

echo "📸 Screenshot 1: Home/Accessories Screen"
echo "Navigate to main Home tab on TV, then press ENTER"
read
xcrun devicectl device screenshot capture --device "$DEVICE" "$OUTPUT/1-Home-Screen.png"

echo ""
echo "📸 Screenshot 2: Rooms View"
echo "Navigate to Rooms tab on TV, then press ENTER"
read
xcrun devicectl device screenshot capture --device "$DEVICE" "$OUTPUT/2-Rooms-View.png"

echo ""
echo "📸 Screenshot 3: Scenes List"
echo "Navigate to Scenes tab on TV, then press ENTER"
read
xcrun devicectl device screenshot capture --device "$DEVICE" "$OUTPUT/3-Scenes-List.png"

echo ""
echo "📸 Screenshot 4: Scene Activation"
echo "Activate a scene on TV (status will appear), then press ENTER"
read
xcrun devicectl device screenshot capture --device "$DEVICE" "$OUTPUT/4-Scene-Activation.png"

echo ""
echo "📸 Screenshot 5: Device Control"
echo "Select a light and show brightness slider on TV, then press ENTER"
read
xcrun devicectl device screenshot capture --device "$DEVICE" "$OUTPUT/5-Device-Control.png"

echo ""
echo "📸 Screenshot 6: More/Settings"
echo "Navigate to More tab on TV, then press ENTER"
read
xcrun devicectl device screenshot capture --device "$DEVICE" "$OUTPUT/6-More-Settings.png"

echo ""
echo "✅ All screenshots captured!"
echo "📁 Location: $OUTPUT/"
ls -lh "$OUTPUT/"
```

## After Capturing

### Verify Screenshots
```bash
ls -lh ~/Desktop/HomeKitTV-Screenshots/
```

Expected: 6 PNG files

### Resize if Needed (App Store requires 1920x1080)
```bash
cd ~/Desktop/HomeKitTV-Screenshots/
for file in *.png; do
    sips -z 1080 1920 "$file" --out "AppStore-$file"
done
```

### Check Sizes
```bash
cd ~/Desktop/HomeKitTV-Screenshots/
file *.png
```

## Tips for Great Screenshots

1. **Clean HomeKit Setup**: Make sure devices are responsive
2. **Good Lighting**: Show variety of device states (some on, some off)
3. **Realistic Data**: Use real device and room names
4. **Show Status**: Capture a scene being executed with status
5. **Variety**: Show different room types and accessories
6. **No Errors**: Avoid showing error states unless showing error handling

## What Apple Looks For

- App interface is clear and usable
- Features are visible
- Text is readable
- No placeholder content
- Professional appearance
- Demonstrates core functionality

## Troubleshooting

### "Device not found"
- Make sure Apple TV is on (not sleeping)
- Check device ID: `xcrun devicectl list devices`

### "Permission denied"
- The Apple TV must be in Developer Mode
- Pair the TV with Xcode if not already paired

### "Command not found"
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`

## Alternative: Use Existing Setup

If you have good photos/videos of HomeKitTV running, you can:
1. Take photos of your TV screen with iPhone
2. Transfer to Mac
3. Crop/resize to 1920x1080
4. Use those for App Store

Not ideal but acceptable for submission.

---

**Save these screenshots** - you'll upload them to App Store Connect when configuring your app listing!
