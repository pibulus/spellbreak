# Code Signing Guide

## Current Status

Ready now:
- app icon assets exist
- local app build works
- local DMG build works
- entitlements file exists
- hardened runtime signing is wired into `build-app.sh`
- bundle identifier is set to `com.pabloalvarado.spellbreak`

Still needed for public release:
- Apple Developer Program membership
- Developer ID signing identity for website distribution
- notary credentials stored in Keychain
- signed and notarized DMG
- screenshots and App Store Connect setup for App Store release

## Local Audit Commands

Use this before calling a build releasable:

```bash
./release-check.sh
```

For unsigned local builds it should report that the app and DMG are not signed. After Developer ID signing and notarization, it should report valid signatures and a stapled notarization ticket.

## Path 1: Website / Direct Download

Use this when you want to host Spellbreak on `spellbreak.app` and let people download a DMG directly.

### 1. Confirm your Developer ID identity
```bash
security find-identity -v -p codesigning
```

You want a line like:

```text
Developer ID Application: Your Name (TEAMID)
```

### 2. Build a signed DMG
```bash
./build-dmg.sh --sign "Developer ID Application: Your Name (TEAMID)"
```

### 3. Verify the signed app
```bash
codesign --verify --verbose build/Spellbreak.app
codesign -dv --verbose=4 build/Spellbreak.app
spctl -a -vvv -t execute build/Spellbreak.app
```

### 4. Store notary credentials once
```bash
xcrun notarytool store-credentials "AC_PASSWORD" \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password"
```

### 5. Notarize and staple the DMG
```bash
xcrun notarytool submit dist/Spellbreak-v1.0.0.dmg \
  --keychain-profile "AC_PASSWORD" \
  --wait

xcrun stapler staple dist/Spellbreak-v1.0.0.dmg
xcrun stapler validate dist/Spellbreak-v1.0.0.dmg
spctl -a -vvv -t open dist/Spellbreak-v1.0.0.dmg
```

### 6. Upload the notarized DMG

That final stapled DMG is the file you want on the website.

## Path 2: Mac App Store

Use this when you want Spellbreak available through the Mac App Store.

### 1. Open the package in Xcode
The direct-download Developer ID path is not the same thing as the App Store path. This SwiftPM repo does not currently contain a dedicated Xcode app project, so App Store submission may need a small Xcode wrapper target before archiving.

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
