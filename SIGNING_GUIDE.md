# Code Signing & Distribution Guide

## Identities

| Use | Identity |
| --- | --- |
| Website / direct DMG | `Developer ID Application: Pablo Alvarado (V433H655PN)` |
| Mac App Store (app) | `Apple Distribution: Pablo Alvarado (V433H655PN)` |
| Mac App Store (installer pkg) | `3rd Party Mac Developer Installer: Pablo Alvarado (V433H655PN)` |
| Notary keychain profile | `AC_PASSWORD` (Apple ID `pibulus@gmail.com`) |

Confirm what's installed locally:

```bash
security find-identity -v -p codesigning
```

## Path 1: Website / Direct Download

Build a signed, notarized DMG for `spellbreak.app`.

```bash
# 1. Build + sign the universal app
./build-app.sh --sign "Developer ID Application: Pablo Alvarado (V433H655PN)"

# 2. Package + sign the DMG
./build-dmg.sh --sign "Developer ID Application: Pablo Alvarado (V433H655PN)"

# 3. Notarize and staple
xcrun notarytool submit dist/Spellbreak-v1.1.0.dmg \
  --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple dist/Spellbreak-v1.1.0.dmg

# 4. Validate
./release-check.sh
spctl -a -vvv -t open dist/Spellbreak-v1.1.0.dmg
```

That stapled DMG is the file to upload to the website.

## Path 2: Mac App Store

```bash
./build-mas.sh
```

This signs with the Apple Distribution / Installer identities and produces
`dist/Spellbreak-v1.1.0-mas.pkg`. Upload it via Transporter.app, or:

```bash
xcrun altool --upload-app -f dist/Spellbreak-v1.1.0-mas.pkg -t macos \
  -u pibulus@gmail.com -p @keychain:AC_PASSWORD
```

MAS builds are a different path from Developer ID — `release-check.sh` checks
Developer ID / hardened-runtime, which MAS builds correctly lack, so do not run
it against the `.pkg`.

## Local dogfood

```bash
./build-app.sh          # unsigned (ad-hoc signed) local app
open build/Spellbreak.app
```

Unsigned builds are fine for testing, beta-only for distribution.

## Screenshots to capture

1. Break overlay in each palette (Aurora, Ember, Violet)
2. Hold-to-skip ring
3. Time tab in preferences
4. Vibes tab in preferences
5. Menu bar popover
6. Heads-up countdown pill

## Sanity checklist

- `./build-app.sh` produces `build/Spellbreak.app`
- `./build-dmg.sh` produces `dist/Spellbreak-v1.1.0.dmg`
- `./build-mas.sh` produces `dist/Spellbreak-v1.1.0-mas.pkg`
- the app launches from the built bundle
- signed app passes `codesign --verify` and `spctl`
- notarized DMG staples successfully
