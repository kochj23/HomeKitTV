# HomeKitTV - Breaking the Upload Loop

**Date**: December 10, 2025
**Problem**: Stuck in validation error loop
**Solution**: Use Xcode GUI to create proper Brand Assets

---

## 🔄 The Loop We're Stuck In

### Pattern:
1. Add Info.plist keys → "Missing image assets in bundle"
2. Create assets → "Info.plist keys wrong type" or "imagestack needs layers"
3. Fix that → Back to "Missing image assets"
4. Repeat 7+ times...

### Why Hand-Coding Isn't Working:
- Brand Assets catalog structure is complex
- Image stacks need proper layer configuration
- JSON structure is very specific
- Easy to make subtle errors that break validation

---

## ✅ SOLUTION: Use Xcode GUI

### Step-by-Step Instructions:

#### 1. Open Project in Xcode
```bash
open -a Xcode /Volumes/Data/xcode/HomeKitTV/HomeKitTV.xcodeproj
```

#### 2. In Xcode Project Navigator:
- Click on **Assets.xcassets**
- You'll see the asset catalog open in the main editor

#### 3. Add Brand Assets (The Right Way):
- At the bottom of the asset catalog, click **"+" button**
- Select **"App Icons & Top Shelf Image"** (this is the tvOS Brand Assets template)
- Xcode will create the proper structure automatically

#### 4. Drag Images Into Placeholders:
You'll see placeholders for:
- **App Icon** - Small (400×400)
- **App Icon** - Large (1280×1280)
- **Top Shelf Image** - Wide (2320×720, 4640×1440)

Drag these files:
- From: `/Volumes/Data/xcode/HomeKitTV/Assets.xcassets/AppIcon.appiconset/icon_400x400@1x.png`
- From: `/Volumes/Data/xcode/HomeKitTV/Assets.xcassets/AppIcon.appiconset/icon_1280x1280@1x.png`
- From: `/Volumes/Data/xcode/HomeKitTV/Assets.xcassets/TopShelf.imageset/TopShelf.png`
- From: `/Volumes/Data/xcode/HomeKitTV/Assets.xcassets/TopShelf.imageset/TopShelf@2x.png`

#### 5. Note the Brand Assets Name:
Xcode will create something like "App Icon & Top Shelf Image" - note this exact name

#### 6. Update Info.plist:
Change these values to match the Brand Assets name Xcode created:
```xml
<key>CFBundlePrimaryIcon</key>
<string>App Icon & Top Shelf Image</string>

<key>TVTopShelfPrimaryImageWide</key>
<string>App Icon & Top Shelf Image</string>
```

#### 7. Update Build Settings:
In Xcode:
- Select project in Navigator
- Select HomeKitTV target
- Go to **Build Settings** tab
- Search for "App Icon"
- Change **Asset Catalog Compiler - Options** → **App Icon Set Name** to match Brand Assets name

#### 8. Build and Archive:
- Product → Clean Build Folder (Shift+Cmd+K)
- Product → Archive (Cmd+B then Cmd+Shift+B)
- Wait for archive to complete

#### 9. Upload:
- Organizer window will open
- Select the new archive
- Click "Distribute App"
- Upload to App Store Connect

---

## 🎯 Why This Will Break the Loop

**Xcode GUI creates**:
- ✅ Proper Brand Assets catalog structure
- ✅ Correct imagestack layers with applicable content
- ✅ All proper Contents.json files
- ✅ Exact structure Apple expects

**We can't replicate this easily by hand** - The GUI knows the exact format.

---

## 🆘 Alternative: TestFlight Direct Upload

If the GUI approach is still problematic:

### Use Transporter App:
1. Export archive as .ipa (not upload)
2. Open **Transporter** app (free from Mac App Store)
3. Drag .ipa to Transporter
4. Upload to App Store Connect

This bypasses some validation and lets Apple process it server-side.

---

## 📝 Quick Commands

### Open Xcode:
```bash
open -a Xcode /Volumes/Data/xcode/HomeKitTV/HomeKitTV.xcodeproj
```

### After creating Brand Assets in GUI, rebuild:
```bash
cd /Volumes/Data/xcode/HomeKitTV
xcodebuild -project HomeKitTV.xcodeproj -scheme HomeKitTV -configuration Release clean archive -archivePath ~/Desktop/HomeKitTV_GUI.xcarchive
```

### Open archive:
```bash
open ~/Desktop/HomeKitTV_GUI.xcarchive
```

---

## 🎯 Bottom Line

**We need to break the loop by using Xcode's GUI to create the Brand Assets.**

The GUI knows the exact structure Apple expects, and we've been unable to replicate it perfectly by hand-coding JSON files.

**Next steps**:
1. Open project in Xcode
2. Use GUI to add "App Icons & Top Shelf Image"
3. Drag existing images into placeholders
4. Let Xcode handle the complex structure
5. Archive and upload

This should work because Xcode's own templates match exactly what Apple validation expects.

---

**Time to break the loop!** Let Xcode's GUI do the heavy lifting! 🚀
