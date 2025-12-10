# Easy Screenshot Method for HomeKitTV

## Issue with Physical Apple TV

Unfortunately, `devicectl` doesn't support screenshots from physical Apple TV devices. HomeKit apps also don't work in simulator (no HomeKit framework).

## ✅ Easiest Methods

### Method 1: iPhone Camera (Simplest!)

**Best for**: Quick and easy, good enough for App Store

1. **Launch HomeKitTV on your Office Apple TV**
2. **Navigate to each screen**
3. **Take photo with iPhone** (landscape orientation)
4. **Transfer photos to Mac** (AirDrop or iCloud Photos)
5. **Crop and resize** (instructions below)

**Advantages:**
- Works immediately
- No special tools needed
- Apple accepts phone photos of TV screens

### Method 2: QuickTime Screen Recording (Higher Quality)

**Best for**: Perfect quality screenshots

1. **Connect Apple TV to Mac**:
   - Use Xcode → Window → Devices and Simulators
   - Select your Office Apple TV
   - Click "Connect via Network" if needed

2. **Open QuickTime Player**:
   - File → New Movie Recording
   - Click dropdown next to record button
   - Select "Office" (your Apple TV)

3. **Record your Apple TV screen**:
   - Navigate through HomeKitTV
   - Record a video showing all screens
   - Stop recording

4. **Extract frames from video**:
   ```bash
   # Pause at good frames and use Cmd+Shift+4 to screenshot
   # Or export frames using QuickTime
   ```

### Method 3: Professional Screenshots (Optional)

Use a screenshot app like:
- **Reflector** (mirrors Apple TV to Mac): https://www.airsquirrels.com/reflector
- **AirServer** (screen mirroring): https://www.airserver.com

## Processing Your Photos

### Step 1: Transfer to Mac
Put all photos in: `~/Desktop/HomeKitTV-Screenshots/`

### Step 2: Crop and Resize to 1920x1080

```bash
cd ~/Desktop/HomeKitTV-Screenshots/

# For each photo, crop and resize:
sips -z 1080 1920 photo1.jpg --out 1-Home-Screen.png
sips -z 1080 1920 photo2.jpg --out 2-Rooms-View.png
sips -z 1080 1920 photo3.jpg --out 3-Scenes-List.png
sips -z 1080 1920 photo4.jpg --out 4-Scene-Activation.png
sips -z 1080 1920 photo5.jpg --out 5-Device-Control.png
sips -z 1080 1920 photo6.jpg --out 6-More-Settings.png
```

### Step 3: Verify

```bash
ls -lh ~/Desktop/HomeKitTV-Screenshots/*.png
file ~/Desktop/HomeKitTV-Screenshots/*.png
```

Should show: 6 PNG files at 1920x1080

## What to Capture (6 Screens)

### 1. Home/Accessories Screen ⭐
**Show**: Main view with HomeKit accessories
**Important**: Show variety of device types (lights, outlets, etc.)

### 2. Rooms View ⭐
**Show**: Devices organized by room
**Important**: Show multiple rooms with accessories

### 3. Scenes Tab ⭐
**Show**: List of available scenes
**Important**: Show scene names clearly

### 4. Scene Activation ⭐
**Show**: Status overlay after activating a scene
**Important**: Shows the new summary format: "X succeeded, Y failed"

### 5. Device Control Detail ⭐
**Show**: Light detail view with brightness slider
**Important**: Shows interactive control

### 6. More/Settings Tab ⭐
**Show**: Settings and additional options
**Important**: Shows app has configuration options

## Screenshot Quality Tips

### Do:
- ✅ Use landscape orientation
- ✅ Take photos straight-on (not at angle)
- ✅ Ensure good lighting
- ✅ Show real data (your actual devices)
- ✅ Make sure text is readable
- ✅ Show app in action (scene being executed)

### Don't:
- ❌ Don't include screen bezel in photo
- ❌ Don't use blurry photos
- ❌ Don't show error states (unless showing error handling)
- ❌ Don't use placeholder names
- ❌ Don't take photos at weird angles

## Apple's Screenshot Requirements

- **Resolution**: 1920x1080 pixels (will be resized if needed)
- **Format**: PNG or JPG
- **Quantity**: 1-10 screenshots (6 is perfect)
- **Quality**: Clear, readable text
- **Content**: Show actual app functionality

## Alternative: Use What You Have

If you have any existing photos or videos of HomeKitTV running, you can use those! Just:
1. Find the best frames
2. Crop to remove bezels
3. Resize to 1920x1080
4. Convert to PNG

Apple reviewers understand HomeKit apps are hard to screenshot - they accept TV screen photos.

## Need Help?

If you want, you can:
1. Take 6 quick photos with your iPhone
2. AirDrop them to your Mac
3. I'll help you crop and resize them for App Store

---

**Bottom line**: iPhone photos of your TV screen are fine for App Store submission. Don't overthink it!

The screenshots just need to show your app works and what it looks like. Quality matters, but perfection isn't required.
