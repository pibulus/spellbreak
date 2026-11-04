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
(currently 1.2.2).

## Path 1: Website / Direct Download

Build a signed, notarized, dual-stapled DMG for `spellbreak.app`:

```bash
# Builds universal build/Spellbreak.app, notarizes + staples the app,
# packages dist/Spellbreak-v1.2.2.dmg, notarizes + staples the DMG, and runs dmg-doctor:
./build-dmg.sh

# Validate all 19 release gates
./release-check.sh
spctl -a -vvv -t open --context context:primary-signature dist/Spellbreak-v1.2.2.dmg
```

That stapled DMG is the file to upload to GitHub Releases (`Spellbreak-v1.2.2.dmg` + stable `Spellbreak.dmg`).

## Path 2: Mac App Store

Needs full Xcode (not just Command Line Tools), both MAS identities above, and
a Mac App Store provisioning profile for `com.pabloalvarado.spellbreak` saved
as `Spellbreak_MAS.provisionprofile` in the repo root (gitignored). The
[submission guide](APP_STORE_SUBMISSION.md) covers creating them via `scripts/asc-provision.ts`.

```bash
./build-mas.sh
./mas-check.sh
```

What `build-mas.sh` does, in order:
1. Preflight, before the slow part: full Xcode selected; profile present, for
   this app ID, and a distribution (not development) profile; both identities
   in the keychain with leaf certificate SHA-1 matching `Spellbreak_MAS.provisionprofile`.
2. Builds the universal app via `build-app.sh` into `build-mas/Spellbreak.app`
   with `SPELLBREAK_APP_STORE=1`, which compiles in `Assets.car`, the 7-day
   trial and unlock (`-DAPP_STORE`, `Store.swift`), and MAS-safe About links
   without clobbering `build/Spellbreak.app`.
3. Stamps the `DT*` / `BuildMachineOSBuild` keys App Store Connect uses to
   identify the Xcode and SDK. `swift build` doesn't write them.
4. Embeds the profile and signs with `Spellbreak.mas.entitlements`, which adds
   the app ID and team ID that Xcode would normally sign in. Without them the
   upload is flagged (ITMS-90886).
5. Verifies the signature, checks the app ID is in it, builds
   `dist/Spellbreak-v1.2.2-mas.pkg`, and checks the package signature.

Upload with **Transporter.app**: sign in, drag in the `.pkg`, then Deliver.
It validates before uploading.

Don't upload with `altool -p @keychain:AC_PASSWORD`. That keychain profile was
made by `notarytool store-credentials`, and altool can't read it.

MAS builds are a different path from Developer ID: validate MAS builds with
`./mas-check.sh` (19 gates) and Developer ID builds with `./release-check.sh` (19 gates).

## Local dogfood

```bash
./build-app.sh          # unsigned (ad-hoc signed) local app
open build/Spellbreak.app
```

Unsigned builds are fine for testing, beta-only for distribution.

## Sanity checklist

- `./build-app.sh` produces `build/Spellbreak.app`
- `./build-dmg.sh` produces `dist/Spellbreak-v1.2.2.dmg` and passes `./release-check.sh`
- `./build-mas.sh` produces `build-mas/Spellbreak.app` + `dist/Spellbreak-v1.2.2-mas.pkg` and passes `./mas-check.sh`
- the app launches from the built bundle
- signed app passes `codesign --verify` and `spctl`
- notarized DMG staples successfully
