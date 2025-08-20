# Code Signing & App Store Submission Guide

## Current Status
✅ App icon structure created (needs actual icon images)
✅ Privacy policy written
✅ App Store description ready
✅ Entitlements file configured
❌ Developer ID needed
❌ App icon images needed

## Getting a Developer ID

### Option 1: Apple Developer Program ($99/year)
1. Go to [developer.apple.com](https://developer.apple.com)
2. Click "Enroll"
3. Choose "Individual" or "Organization"
4. Complete enrollment ($99 USD/year)
5. Wait for approval (usually 24-48 hours)

### Option 2: Free Developer Account (Testing Only)
- Can test on your own Mac
- Can't distribute to others
- Can't submit to App Store

## Once You Have Developer ID

### 1. Create App Icon Images
You'll need these sizes (all PNG format):
- 16x16, 32x32 (16x16@2x)
- 32x32, 64x64 (32x32@2x)  
- 128x128, 256x256 (128x128@2x)
- 256x256, 512x512 (256x256@2x)
- 512x512, 1024x1024 (512x512@2x)

Save them in: `Assets.xcassets/AppIcon.appiconset/`

### 2. Update Package.swift
Add the icon to your resources:
```swift
resources: [
    .copy("Assets.xcassets")
]
```

### 3. Sign the App
```bash
# Find your Developer ID
security find-identity -v -p codesigning

# Sign the app
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  --entitlements Spellbreak.entitlements \
  Spellbreak.app

# Verify signature
codesign --verify --verbose Spellbreak.app
spctl -a -vvv Spellbreak.app
```

### 4. Create DMG for Distribution
```bash
# Create a DMG
hdiutil create -volname "Spellbreak" \
  -srcfolder Spellbreak.app \
  -ov -format UDZO \
  Spellbreak.dmg

# Sign the DMG
codesign --sign "Developer ID Application: Your Name (TEAM_ID)" \
  Spellbreak.dmg
```

### 5. Notarize the App
```bash
# Store credentials
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password"

# Submit for notarization
xcrun notarytool submit Spellbreak.dmg \
  --keychain-profile "AC_PASSWORD" \
  --wait

# Staple the ticket
xcrun stapler staple Spellbreak.dmg
```

### 6. App Store Submission

#### Via Xcode (Recommended)
1. Open project in Xcode
2. Product → Archive
3. Distribute App → App Store Connect
4. Follow upload wizard

#### Via Transporter
1. Download Transporter from Mac App Store
2. Export app as .pkg
3. Upload via Transporter

## App Store Connect Setup

1. Log into [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Create new macOS app
3. Fill in:
   - App name: Spellbreak
   - Bundle ID: com.yourname.spellbreak
   - SKU: SPELLBREAK001
4. Upload screenshots (1280x800 minimum)
5. Add description from APP_STORE.md
6. Set pricing: Free
7. Submit for review

## Screenshots Needed
Run the app and capture:
1. Full break overlay with aurora effect
2. Menu bar dropdown showing timer
3. Preferences window - Time tab
4. Preferences window - Vibes tab  
5. Different visual themes
6. Hold-to-skip interface in action

## Testing Checklist
- [ ] App launches without crash
- [ ] Break timer works correctly
- [ ] Hold-to-skip mechanism functions
- [ ] Preferences save and persist
- [ ] Launch at login works
- [ ] All visual themes display correctly
- [ ] Sound effects play (if enabled)
- [ ] Memory usage stays reasonable
- [ ] No console errors

## Distribution Without App Store

If you want to distribute outside App Store:
1. Sign with Developer ID (not App Store cert)
2. Notarize the app
3. Create DMG with app and alias to /Applications
4. Host on your website
5. Users will need to right-click → Open on first launch

## Troubleshooting

**"App is damaged" error**
- Not properly signed or notarized
- Check: `spctl -a -vvv Spellbreak.app`

**"Unidentified developer" warning**
- Need Developer ID certificate
- Or users can right-click → Open

**Notarization fails**
- Check entitlements match capabilities
- Ensure all frameworks are signed
- Review rejection email for specifics

---

*The spell of distribution requires patience and proper certificates* 🔮