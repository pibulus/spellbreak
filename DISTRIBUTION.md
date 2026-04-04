# Spellbreak Distribution Guide

## Current Repo Reality

Spellbreak now builds locally as:

- `build/Spellbreak.app`
- `dist/Spellbreak-v1.0.0.dmg`

The build scripts produce a universal app binary when both `arm64` and `x86_64` builds succeed, and they fall back cleanly to a single-arch app if the second architecture cannot be built on the current machine.

## Direct Distribution

For friends, website downloads, and general outside-the-App-Store shipping:

1. Build a signed app + DMG
   ```bash
   ./build-dmg.sh --sign "Developer ID Application: Your Name (TEAMID)"
   ```
2. Notarize the DMG
   ```bash
   xcrun notarytool submit dist/Spellbreak-v1.0.0.dmg \
     --keychain-profile "AC_PASSWORD" \
     --wait

   xcrun stapler staple dist/Spellbreak-v1.0.0.dmg
   ```
3. Upload the notarized DMG to `spellbreak.app`

Unsigned builds are fine for local testing, but they should be treated as beta-only artifacts.

## Mac App Store

Mac App Store submission is a different path from Developer ID distribution.

- Developer ID: website / direct download / notarized DMG
- Mac App Store: archive in Xcode, upload to App Store Connect, submit for review

Use the App Store path when you want:

- native App Store installation
- automatic update flow through Apple
- App Store review and listing

## Recommended Release Flow

### Local dogfood
```bash
./build-app.sh
open build/Spellbreak.app
```

### Website beta
```bash
./build-dmg.sh --sign "Developer ID Application: Your Name (TEAMID)"
```

### App Store prep
- capture screenshots from the current build
- archive in Xcode
- upload that archive to App Store Connect

## File Map

```text
spellbreak/
├── build/Spellbreak.app
├── dist/Spellbreak-v1.0.0.dmg
├── build-app.sh
├── build-dmg.sh
├── SIGNING_GUIDE.md
└── APP_STORE.md
```

## Notes

- `Spellbreak-v1.0-unsigned.zip` is a legacy beta artifact and should not be treated as the source of truth for current release status.
- If Gatekeeper complains about an unsigned local build, that is expected until you sign + notarize the DMG.
