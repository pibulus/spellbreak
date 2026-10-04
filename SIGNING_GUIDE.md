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
security find-identity -v
```

File names below use the version in `Sources/Spellbreak/Resources/Info.plist`
(currently 1.2.0).

## Path 1: Website / Direct Download

Build a signed, notarized DMG for `spellbreak.app`.

```bash
# 1. Build + sign the universal app
./build-app.sh --sign "Developer ID Application: Pablo Alvarado (V433H655PN)"

# 2. Package + sign the DMG
./build-dmg.sh --sign "Developer ID Application: Pablo Alvarado (V433H655PN)"

# 3. Notarize and staple
xcrun notarytool submit dist/Spellbreak-v1.2.0.dmg \
  --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple dist/Spellbreak-v1.2.0.dmg

# 4. Validate
./release-check.sh
spctl -a -vvv -t open dist/Spellbreak-v1.2.0.dmg
```

That stapled DMG is the file to upload to the website.

## Path 2: Mac App Store

Needs full Xcode (not just Command Line Tools), both MAS identities above, and
a Mac App Store provisioning profile for `com.pabloalvarado.spellbreak` saved
as `Spellbreak_MAS.provisionprofile` in the repo root (gitignored). The
[submission guide](APP_STORE_SUBMISSION.md) covers creating them.

```bash
./build-mas.sh
```

What it does, in order:
1. Preflight, before the slow part: full Xcode selected; profile present, for
   this app ID, and a distribution (not development) profile; both identities
   in the keychain.
2. Builds the universal app via `build-app.sh` with `SPELLBREAK_APP_STORE=1`,
   which compiles in the 7-day trial and unlock (`-DAPP_STORE`, `Store.swift`).
   Website builds leave it out. Refuses an arm64-only binary.
3. Stamps the `DT*` / `BuildMachineOSBuild` keys App Store Connect uses to
   identify the Xcode and SDK. `swift build` doesn't write them.
4. Embeds the profile and signs with `Spellbreak.mas.entitlements`, which adds
   the app ID and team ID that Xcode would normally sign in. Without them the
   upload is flagged (ITMS-90886).
5. Verifies the signature, checks the app ID is in it, builds
   `dist/Spellbreak-v1.2.0-mas.pkg`, and checks the package signature.

Upload with **Transporter.app**: sign in, drag in the `.pkg`, then Deliver.
It validates before uploading.

Don't upload with `altool -p @keychain:AC_PASSWORD`. That keychain profile was
made by `notarytool store-credentials`, and altool can't read it.

MAS builds are a different path from Developer ID. `release-check.sh` checks
Developer ID and hardened runtime, which MAS builds correctly lack, so don't
run it against the `.pkg`.

## Local dogfood

```bash
./build-app.sh          # unsigned (ad-hoc signed) local app
open build/Spellbreak.app
```

Unsigned builds are fine for testing, beta-only for distribution.

## Sanity checklist

- `./build-app.sh` produces `build/Spellbreak.app`
- `./build-dmg.sh` produces `dist/Spellbreak-v1.2.0.dmg`
- `./build-mas.sh` produces `dist/Spellbreak-v1.2.0-mas.pkg`
- the app launches from the built bundle
- signed app passes `codesign --verify` and `spctl`
- notarized DMG staples successfully
