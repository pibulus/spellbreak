# Code Signing Guide

## Current Status

Ready now:
- app icon assets exist
- local app build works
- local DMG build works
- entitlements file exists
- bundle identifier is set to `com.pabloalvarado.spellbreak`

Still needed for public release:
- Apple Developer Program membership
- Developer ID signing identity for website distribution
- notarization for the DMG
- screenshots and App Store Connect setup for App Store release

## Path 1: Website / Direct Download

Use this when you want to host Spellbreak on `spellbreak.app` and let people download a DMG directly.

### 1. Build a signed DMG
```bash
./build-dmg.sh --sign "Developer ID Application: Your Name (TEAMID)"
```

### 2. Verify the signed app
```bash
codesign --verify --verbose build/Spellbreak.app
spctl -a -vvv build/Spellbreak.app
```

### 3. Notarize the DMG
```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password"

xcrun notarytool submit dist/Spellbreak-v1.0.0.dmg \
  --keychain-profile "AC_PASSWORD" \
  --wait

xcrun stapler staple dist/Spellbreak-v1.0.0.dmg
```

### 4. Upload the notarized DMG

That final stapled DMG is the file you want on the website.

## Path 2: Mac App Store

Use this when you want Spellbreak available through the Mac App Store.

### 1. Open the package in Xcode
Use Xcode to archive the app. The direct-download Developer ID path is not the same thing as the App Store path.

### 2. Archive the app
- Product → Archive
- Validate the archive
- Upload it to App Store Connect

### 3. Complete App Store Connect
- app name: `Spellbreak`
- bundle id: `com.pabloalvarado.spellbreak`
- pricing: free
- upload screenshots
- paste the description from `APP_STORE.md`

### 4. Submit for review

Apple will review the Mac App Store build separately from your Developer ID DMG.

## Screenshots To Capture

1. Main break overlay
2. Menu bar timer view
3. Time tab in preferences
4. Vibes tab in preferences
5. Hold-to-skip ring
6. A heads-up notification or warning state

## Sanity Checklist

- `./build-app.sh` produces `build/Spellbreak.app`
- `./build-dmg.sh` produces `dist/Spellbreak-v1.0.0.dmg`
- the app launches from the built bundle
- timer survives relaunch cleanly
- autostart status reports honestly
- sound toggles and volume do what they say
- signed app passes `codesign` and `spctl`
- notarized DMG staples successfully
