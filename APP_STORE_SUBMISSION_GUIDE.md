# HomeKitTV - Complete Apple App Store Submission Guide

## Current App Status

- **App Name**: HomeKitTV
- **Bundle ID**: com.kochj.HomeKitTV
- **Version**: 3.1 (needs alignment with MARKETING_VERSION)
- **Build**: 11
- **Platform**: tvOS
- **Category**: HomeKit control application

## Prerequisites Checklist

### 1. Apple Developer Program Membership ($99/year)
- [ ] Enroll at: https://developer.apple.com/programs/enroll/
- [ ] Wait for approval (usually 24-48 hours)
- [ ] Note your Team ID (currently: QRRCB8HB3W - verify this is active)

### 2. App Store Connect Access
- [ ] Access: https://appstoreconnect.apple.com
- [ ] Verify you can log in with your Apple ID
- [ ] Accept any agreements/contracts

### 3. Required Materials
- [ ] App icon (Home.png - ✅ Done)
- [ ] App screenshots (see requirements below)
- [ ] App description and keywords
- [ ] Privacy policy URL (required for HomeKit apps)
- [ ] Support URL
- [ ] Marketing URL (optional)

## Step-by-Step Submission Process

### Phase 1: Prepare App Metadata (Before Upload)

#### Step 1: Create App in App Store Connect
1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: tvOS
   - **Name**: HomeKitTV (or your preferred public name)
   - **Primary Language**: English
   - **Bundle ID**: Select `com.kochj.HomeKitTV`
   - **SKU**: HOMEKITTV001 (unique identifier for your records)
   - **User Access**: Full Access

#### Step 2: App Information
1. Click on your new app
2. Go to "App Information"
3. Fill in:
   - **Name**: HomeKitTV
   - **Subtitle**: Control Your HomeKit Devices from Apple TV (max 30 chars)
   - **Category**: Primary: Utilities, Secondary: Lifestyle
   - **Content Rights**: Check if you have rights to use all content

#### Step 3: Pricing and Availability
1. Go to "Pricing and Availability"
2. Set:
   - **Price**: Free (or select a price tier)
   - **Availability**: All territories (or select specific countries)
   - **Pre-orders**: Not applicable for first release

#### Step 4: Privacy Policy (REQUIRED for HomeKit)
HomeKit apps MUST have a privacy policy. Create one that covers:
- What HomeKit data you access
- How you use it (only for device control)
- That you don't collect or share user data
- Storage of HomeKit configurations

**Quick Solution**: Host a privacy policy page or use a service like:
- GitHub Pages (free)
- Your own website
- Privacy policy generators

**Sample Privacy Policy**:
```markdown
# HomeKitTV Privacy Policy

## Data Collection
HomeKitTV does not collect, store, or transmit any personal information or HomeKit data outside of your local network.

## HomeKit Usage
- Accesses your HomeKit accessories only for control purposes
- All HomeKit data remains on your device
- No data is sent to external servers
- No analytics or tracking

## Permissions
- HomeKit: Required to control your home accessories

Contact: [your-email@example.com]
Last Updated: December 10, 2025
```

Host this at: https://yourdomain.com/homekittv-privacy or https://github.com/kochj23/HomeKitTV/wiki/Privacy-Policy

### Phase 2: Prepare App for Submission

#### Step 5: Update Version Numbers
Currently mismatched - need to align:

```bash
cd "/Volumes/Data/xcode/HomeKitTV"
# Update to version 1.0 for initial App Store release
```

In Xcode:
1. Select project in Navigator
2. Select HomeKitTV target
3. General tab:
   - **Version**: 1.0 (clean start for App Store)
   - **Build**: 1 (increment for each submission)

Or update Info.plist:
- CFBundleShortVersionString: 1.0
- CFBundleVersion: 1

#### Step 6: Create Screenshots (REQUIRED)

**tvOS Screenshot Requirements:**
- **Size**: 1920x1080 pixels
- **Format**: PNG or JPG
- **Quantity**: 1-10 screenshots
- **Content**: Show your app's main features

**How to capture:**
1. Run HomeKitTV on Apple TV Simulator or device
2. Navigate to key screens
3. Capture screenshots:
   - Home screen with accessories
   - Rooms view
   - Scenes view
   - A scene being activated
   - Settings screen

**Using Simulator:**
```bash
xcrun simctl io booted screenshot screenshot1.png
```

**Using Device:**
```bash
xcrun devicectl device screenshot --device [DEVICE_ID] --output screenshot.png
```

#### Step 7: Write App Store Description

**App Name Ideas:**
- HomeKitTV
- HomeKit TV Controller
- HomeKit Remote for Apple TV

**Description Template** (max 4000 characters):
```
Control your entire HomeKit smart home from your Apple TV with HomeKitTV!

FEATURES:
• Full HomeKit Integration - Control all your HomeKit accessories
• Organized by Rooms - Easy navigation through your home
• Scene Activation - Execute multi-device scenes with one tap
• Real-time Status - See device status updates instantly
• Beautiful tvOS Interface - Optimized for TV remote navigation
• Support for Multiple Device Types:
  - Lights (on/off, brightness, color)
  - Outlets and Switches
  - Thermostats
  - Fans
  - And more!

PERFECT FOR:
• Controlling lights from your couch
• Activating scenes for movie time, bedtime, etc.
• Quick access to frequently used devices
• Whole-home control without reaching for your phone

REQUIREMENTS:
• Apple TV 4K or Apple TV HD
• iOS/iPadOS devices with HomeKit setup
• HomeKit-compatible accessories
• Same network as your HomeKit hub

PRIVACY:
• No data collection
• All HomeKit data stays local
• No internet connection required for operation
• Your privacy is protected

Easy to use, beautiful interface, complete HomeKit control on your TV!
```

**Keywords** (max 100 characters, comma-separated):
```
homekit,smart home,home automation,control,lights,scenes,accessories,remote
```

#### Step 8: App Review Information
Prepare for review team:

**Demo Account**: Not needed (HomeKit apps don't require login)

**Notes for Reviewer**:
```
HomeKitTV requires HomeKit accessories to test.

For review purposes:
1. The app will show "No homes available" if no HomeKit setup exists
2. To fully test, the reviewer needs HomeKit accessories on their network
3. Basic navigation and UI can be tested without accessories
4. We've included screenshots showing full functionality

Contact: [your-email] if you need assistance during review.
```

**Contact Information**:
- Email: [your-email@example.com]
- Phone: [your-phone-number]

### Phase 3: Build and Submit

#### Step 9: Prepare for Archive

**Clean the project:**
```bash
cd "/Volumes/Data/xcode/HomeKitTV"
xcodebuild clean -project HomeKitTV.xcodeproj -scheme HomeKitTV
```

**Update version to 1.0.0:**
- Update Info.plist CFBundleShortVersionString to "1.0.0"
- Update CFBundleVersion to "1"

**Verify settings:**
- Signing: "Automatically manage signing" ON
- Team: Your Apple Developer Team
- Provisioning Profile: App Store
- Code Signing Identity: Apple Distribution

#### Step 10: Archive the App

```bash
cd "/Volumes/Data/xcode/HomeKitTV"
xcodebuild -project HomeKitTV.xcodeproj \
  -scheme HomeKitTV \
  -configuration Release \
  -archivePath ~/Desktop/HomeKitTV.xcarchive \
  archive
```

Or in Xcode:
1. Product menu → Destination → Any tvOS Device (arm64)
2. Product menu → Archive
3. Wait for archive to complete
4. Organizer window will open automatically

#### Step 11: Validate the Archive

In Xcode Organizer:
1. Select your archive
2. Click "Validate App"
3. Choose distribution method: "App Store Connect"
4. Select your team
5. Choose automatic signing
6. Click "Validate"
7. Fix any errors/warnings that appear

**Common validation issues:**
- Missing privacy policy URL
- Invalid bundle ID
- Code signing errors
- Missing entitlements
- Icon issues

#### Step 12: Upload to App Store Connect

After validation passes:
1. Click "Distribute App"
2. Choose "App Store Connect"
3. Select "Upload"
4. Choose automatic signing
5. Review content rights
6. Click "Upload"
7. Wait for upload to complete (may take 10-30 minutes)

**Alternative: Command Line Upload**
```bash
xcrun altool --upload-app \
  --type appletvos \
  --file HomeKitTV.ipa \
  --username your-apple-id@example.com \
  --password @keychain:AC_PASSWORD
```

#### Step 13: Complete App Store Connect Listing

After upload completes:
1. Go to App Store Connect → My Apps → HomeKitTV
2. Click the "+" next to tvOS or "Prepare for Submission"
3. Select the build you just uploaded
4. Fill in all required fields:

**Version Information:**
- **What's New in This Version**: Describe new features
- **Promotional Text**: Short tagline (optional, can update without new build)
- **Description**: Your full app description
- **Keywords**: Smart home keywords
- **Support URL**: Link to support page
- **Marketing URL**: (optional)
- **Screenshots**: Upload your 1920x1080 screenshots
- **App Preview**: (optional video)

**General App Information:**
- **App Icon**: Automatically pulled from build
- **Category**: Utilities
- **Content Rights**: Confirm
- **Age Rating**: Complete questionnaire (likely 4+)

**App Review Information:**
- **Contact**: Your email and phone
- **Demo Account**: N/A
- **Notes**: Add testing instructions
- **Attachments**: (optional)

### Phase 4: Submit for Review

#### Step 14: Submit

1. Review all information for accuracy
2. Check "Export Compliance Information"
   - **Does your app use encryption?** Yes (HTTPS)
   - **Does it qualify for exemption?** Yes (standard HTTPS)
3. Click "Add for Review"
4. Click "Submit for Review"

**Review Timeline:**
- Typical: 24-48 hours
- Can be faster (12 hours) or slower (5-7 days)
- Check email for updates

### Phase 5: Handle App Review

#### Possible Outcomes:

**1. Approved ✅**
- App goes live automatically (or on scheduled date)
- You'll receive email confirmation
- Monitor App Store Connect for analytics

**2. Rejected ❌**
- Common HomeKit app rejections:
  - **Missing privacy policy**: Add URL and resubmit
  - **Unclear functionality**: Improve screenshots/description
  - **Crashes during review**: Fix bugs and resubmit
  - **Guideline violations**: Address feedback

**How to handle rejection:**
1. Read rejection reason carefully
2. Address ALL issues mentioned
3. Respond in Resolution Center
4. Upload new build if code changes needed
5. Resubmit for review

#### Step 15: Post-Approval

**Your app is live! Now what?**

1. **Monitor reviews**: Respond to user feedback
2. **Track analytics**: App Store Connect → Analytics
3. **Plan updates**: Fix bugs, add features
4. **Promote**: Share on social media, forums

**Future Updates:**
- Increment version: 1.0 → 1.1 → 2.0
- Increment build for each submission
- Repeat archive → upload → review process

## Important Considerations for HomeKitTV

### 1. Privacy Policy is MANDATORY
HomeKit apps MUST have a privacy policy URL. Without it, you'll be rejected immediately.

### 2. HomeKit Entitlement
Your app already has HomeKit entitlement in HomeKitTV.entitlements. Good!

### 3. Testing for Reviewers
Consider these strategies:
- Provide detailed testing instructions
- Note that basic UI navigation works without HomeKit
- Offer to provide test credentials if you have a demo setup
- Include video showing the app working

### 4. App Store Guidelines Compliance
Review:
- https://developer.apple.com/app-store/review/guidelines/
- Section 2.5.13: HomeKit apps must use HomeKit APIs appropriately
- Section 5.1: Privacy - data collection disclosure

### 5. Marketing Materials

**App Name Strategy:**
- Check if "HomeKitTV" is available
- Consider alternatives: "HomeKit Controller", "HomeKit Remote"
- Keep it descriptive and searchable

**Icon Considerations:**
- Your Home.png icon looks good
- Ensure it's not confusingly similar to Apple's Home app
- Should be distinctive and recognizable

### 6. Version Numbering Strategy

**For Initial Release:**
- Marketing Version: 1.0.0 (what users see)
- Build Number: 1 (increments with each upload)

**For Future Updates:**
- Bug fixes: 1.0.0 → 1.0.1
- Minor features: 1.0.0 → 1.1.0
- Major updates: 1.0.0 → 2.0.0

## Quick Start Checklist

Before you can submit, you MUST have:

- [ ] Active Apple Developer Program membership
- [ ] Privacy policy URL hosted and accessible
- [ ] Support URL or email
- [ ] App Store Connect account set up
- [ ] 1-10 tvOS screenshots (1920x1080)
- [ ] App description written (under 4000 chars)
- [ ] Keywords selected (under 100 chars)
- [ ] Version numbers aligned (1.0.0 build 1)
- [ ] App signed with Distribution certificate
- [ ] HomeKit usage description clear
- [ ] Age rating questionnaire completed

## Estimated Timeline

| Step | Time Required |
|------|---------------|
| Apple Developer enrollment | 24-48 hours |
| Create privacy policy | 1-2 hours |
| Take screenshots | 1-2 hours |
| Write description | 1-2 hours |
| Configure App Store Connect | 2-3 hours |
| Archive and upload | 30-60 minutes |
| **First-time setup total** | **2-4 days** |
| | |
| App Review | 24-48 hours (typical) |
| **Total to live** | **3-6 days** |

## Commands to Run

### 1. Update Version for App Store

```bash
cd "/Volumes/Data/xcode/HomeKitTV"

# Update Info.plist
plutil -replace CFBundleShortVersionString -string "1.0.0" Info.plist
plutil -replace CFBundleVersion -string "1" Info.plist
```

### 2. Archive for App Store

```bash
cd "/Volumes/Data/xcode/HomeKitTV"

xcodebuild -project HomeKitTV.xcodeproj \
  -scheme HomeKitTV \
  -configuration Release \
  -archivePath ~/Desktop/HomeKitTV.xcarchive \
  archive

# Then open Organizer
open ~/Library/Developer/Xcode/Archives/
```

### 3. Capture Screenshots

```bash
# On Apple TV Simulator
open -a Simulator
# Launch your app, navigate to screens
xcrun simctl io booted screenshot ~/Desktop/HomeKitTV-Screenshot-1.png

# Or on physical device
xcrun devicectl device screenshot \
  --device 915604CB-97FF-5F2E-9AE6-15AEB8852719 \
  --output ~/Desktop/HomeKitTV-Screenshot-1.png
```

## What Happens After Submission

### Review Process
1. **In Review**: Apple is testing your app (12-48 hours)
2. **Pending Developer Release**: Approved! Waiting for you to release
3. **Ready for Sale**: Live on App Store!

### If Rejected
1. Read feedback carefully
2. Fix all issues
3. Respond in Resolution Center
4. Upload new build if needed
5. Resubmit

### If Approved
1. **App goes live** on App Store
2. Users can download
3. Monitor reviews and ratings
4. Plan first update

## Common Rejection Reasons (and Fixes)

### 1. Missing Privacy Policy
**Rejection**: "Your app is missing a privacy policy URL"
**Fix**: Create and host privacy policy, add URL in App Store Connect

### 2. Incomplete Information
**Rejection**: "Screenshots don't show app functionality"
**Fix**: Add more detailed screenshots with captions

### 3. Crashes
**Rejection**: "App crashed during review when we tapped X"
**Fix**: Test thoroughly, fix crash, resubmit

### 4. Guideline 2.5.13 - HomeKit
**Rejection**: "App doesn't clearly indicate HomeKit requirement"
**Fix**: Update description to emphasize HomeKit requirement upfront

### 5. Metadata Issues
**Rejection**: "Description contains inappropriate language"
**Fix**: Keep description professional, no superlatives

## Post-Launch Strategy

### Week 1-2 After Launch
- Monitor crash reports in App Store Connect
- Respond to user reviews (first 24 hours critical!)
- Fix any critical bugs immediately
- Prepare version 1.0.1 if needed

### Month 1
- Analyze user feedback
- Plan feature updates
- Build version 1.1.0 roadmap

### Ongoing
- Regular updates every 2-3 months
- Respond to reviews within 48 hours
- Monitor iOS updates for compatibility

## Resources

### Apple Documentation
- **App Store Connect Help**: https://help.apple.com/app-store-connect/
- **App Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **HomeKit Guidelines**: https://developer.apple.com/homekit/
- **tvOS Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/tvos

### Support
- **Developer Forums**: https://developer.apple.com/forums/
- **Technical Support**: https://developer.apple.com/contact/
- **App Review**: reviewappealsteam@apple.com (only for appeals)

## Immediate Next Steps

1. **Today**:
   - Enroll in Apple Developer Program (if not already)
   - Create privacy policy
   - Take screenshots

2. **Tomorrow**:
   - Set up App Store Connect listing
   - Write app description
   - Upload metadata

3. **Day 3**:
   - Archive app
   - Upload to App Store Connect
   - Submit for review

4. **Day 4-6**:
   - Wait for review
   - Monitor email for updates

## Cost Summary

- **Apple Developer Program**: $99/year (required)
- **Privacy Policy Hosting**: $0 (GitHub Pages) or $10-50/year (domain)
- **Support Page**: $0 (GitHub) or included with domain
- **Marketing**: Optional
- **Total Minimum**: $99/year

## Need Help?

If you get stuck:
1. Check Apple's App Store Connect Help
2. Visit Apple Developer Forums
3. Review rejection reasons carefully (they're usually specific)
4. Consider hiring an iOS consultant for first submission

---

**Ready to proceed? Let me know if you want me to:**
1. Update version numbers to 1.0.0
2. Create a privacy policy template
3. Generate screenshot capture scripts
4. Help with any specific step

**Built by Jordan Koch**
