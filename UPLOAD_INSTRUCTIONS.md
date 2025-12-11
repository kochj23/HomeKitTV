# HomeKitTV - App Store Connect Upload Instructions

## ✅ Archive Created Successfully!

**Archive Location**: `/tmp/HomeKitTV.xcarchive`
**Version**: 1.0.0
**Build**: 1
**Date**: December 10, 2025

---

## 🚀 Step-by-Step Upload Process

### Step 1: Xcode Organizer (Currently Open)

The Xcode Organizer window should now be open with your HomeKitTV archive selected.

### Step 2: Distribute App

1. In the Organizer window, you should see your **HomeKitTV** archive
2. Click the **"Distribute App"** button on the right side
3. A dialog will appear asking "Select a destination"

### Step 3: Select Distribution Method

Choose one of these options:

#### Option A: Upload Directly (Recommended)
1. Select **"App Store Connect"**
2. Click **"Next"**
3. Choose **"Upload"** (not "Export")
4. Click **"Next"**
5. Xcode will automatically manage signing

#### Option B: Export for Manual Upload
1. Select **"App Store Connect"**
2. Click **"Next"**
3. Choose **"Export"**
4. Select a folder to save the .ipa file
5. Upload later using Transporter app

### Step 4: Automatic Signing

1. Xcode will show **"Automatically manage signing"**
2. Select your **Team**: QRRCB8HB3W (Jordan Koch)
3. Click **"Next"**
4. Xcode will automatically create/download provisioning profiles

### Step 5: Review Content

1. Review the app information
2. Check that:
   - **App**: HomeKitTV
   - **Version**: 1.0.0
   - **Build**: 1
   - **Platforms**: tvOS
3. Click **"Next"**

### Step 6: Upload

1. Xcode will prepare the app for upload
2. This may take a few minutes
3. You'll see a progress bar
4. When complete, you'll see **"Upload Successful"**

---

## 🔑 What If You See Errors?

### Error: "No Apple ID added"
1. Go to **Xcode** → **Settings** → **Accounts**
2. Click **"+"** to add your Apple ID
3. Sign in with: kochj@digitalnoise.net (or your Apple ID)
4. Select your team

### Error: "No provisioning profile"
This is expected! Xcode will automatically create one during the upload process.

### Error: "Missing compliance information"
This appears in App Store Connect after upload. Answer:
- Does your app use encryption? **Yes** (HTTPS)
- Export compliance: Select **"No, your app only uses standard encryption"**

---

## ✅ After Upload

### 1. Verify Upload in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Click **"My Apps"**
3. You should see **HomeKitTV** listed
4. Click on it
5. Go to **"Activity"** tab
6. You should see Build **1.0.0 (1)** processing

### 2. Processing Time

- Initial processing: **10-30 minutes**
- You'll receive an email when processing is complete
- Status will change from "Processing" to "Ready to Submit"

### 3. Next Steps (After Processing)

Once build is processed, you need to:

1. **Create App Store Listing** (if not done yet)
   - App name
   - Description
   - Keywords
   - Screenshots (required!)
   - App icon

2. **Add Build to Version**
   - Go to your app in App Store Connect
   - Click on **"1.0 Prepare for Submission"**
   - Under **"Build"**, click **"+"**
   - Select build **1.0.0 (1)**

3. **Required Materials**
   - [ ] App screenshots (1920x1080 for Apple TV)
   - [ ] App description (up to 4000 characters)
   - [ ] Keywords (max 100 characters)
   - [ ] Privacy policy URL (**REQUIRED for HomeKit apps**)
   - [ ] Support URL
   - [ ] App icon (already have: Home.png)

4. **Privacy Policy** (CRITICAL!)
   HomeKit apps MUST have a privacy policy. Quick options:
   - GitHub: https://github.com/kochj23/HomeKitTV/blob/main/PRIVACY_POLICY.md
   - Host on your website
   - Use: https://yourdomain.com/homekittv-privacy

---

## 📸 Screenshot Requirements

For tvOS apps, you need **at least 1 screenshot**:
- **Resolution**: 1920×1080 pixels
- **Format**: PNG or JPG
- **Quantity**: 1-10 screenshots

### Taking Screenshots:

There's a script ready: `/Volumes/Data/xcode/HomeKitTV/capture-screenshots.sh`

Or use the simulator:
1. Open HomeKitTV in Xcode
2. Run on Apple TV Simulator
3. Take screenshots: **Cmd + S**
4. Screenshots saved to Desktop

---

## 🎯 Quick Checklist

Before submitting to App Store:

- [ ] Build uploaded and processed
- [ ] App Store listing created
- [ ] App name: "HomeKitTV" (or your choice)
- [ ] Description written
- [ ] Keywords added
- [ ] Screenshots uploaded (1920x1080)
- [ ] App icon uploaded (1024x1024)
- [ ] Privacy policy URL added
- [ ] Support URL added
- [ ] Export compliance answered
- [ ] Age rating set
- [ ] Pricing set (Free or Paid)
- [ ] Territories selected
- [ ] Build added to version
- [ ] Click **"Submit for Review"**

---

## 📧 What Happens Next?

1. **Upload Complete** (now)
   - Build is uploading to Apple servers

2. **Processing** (10-30 minutes)
   - Apple processes your app
   - Checks for issues
   - Generates download sizes

3. **Waiting for Review** (after you submit)
   - Your app enters the review queue
   - Typical wait: 24-48 hours

4. **In Review**
   - Apple is reviewing your app
   - Usually takes a few hours to 1 day

5. **Ready for Sale** (or Rejected)
   - If approved: App goes live!
   - If rejected: Fix issues and resubmit

---

## 🆘 Need Help?

### Resources:
- App Store Connect: https://appstoreconnect.apple.com
- Developer Portal: https://developer.apple.com/account
- Submission Guide: `/Volumes/Data/xcode/HomeKitTV/APP_STORE_SUBMISSION_GUIDE.md`
- App Description: `/Volumes/Data/xcode/HomeKitTV/APP_STORE_DESCRIPTION.md`

### Common Issues:
- **Can't log in**: Use your Apple ID (kochj@digitalnoise.net)
- **No team**: Verify Apple Developer Program membership
- **Missing screenshots**: Use Icon Creator Screenshot Resizer to resize images to 1920×1080!
- **Privacy policy**: Required for HomeKit apps - see PRIVACY_POLICY.md

---

## 🎉 You're Almost There!

Once the build finishes uploading:
1. Complete the App Store listing
2. Add screenshots (use the new Screenshot Resizer feature!)
3. Add privacy policy URL
4. Submit for review
5. Wait for approval (usually 1-2 days)

**Good luck with your submission!**

---

**Created**: December 10, 2025
**Archive**: /tmp/HomeKitTV.xcarchive
**Version**: 1.0.0 (Build 1)
