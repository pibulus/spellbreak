# Spellbreak — Project Guide

A full-screen break reminder for macOS. A chosen interval becomes a pause that
covers every display; a 2–3 second hold leaves it early, and **Lock mode** takes
that hold away. Street-smart occult, never corporate wellness.

- **Domain**: spellbreak.app
- **Site**: `~/Projects/active/mac/spellbreak-site` (Fresh + Deno Deploy)
- **Stack**: Swift 5.9+, SwiftUI, macOS 13+, Swift Package Manager
- **Bundle ID**: `com.pabloalvarado.spellbreak` (MAS: `.SpellbreakMAS`)
- **Team**: V433H655PN

`CLAUDE.md` is a symlink to this file. Edit this one.

---

## Status

**v1.2.1 shipped** — `dist/Spellbreak-v1.2.1.dmg` is Developer ID signed,
notarized and dual-stapled, and published as GitHub release `v1.2.1` with both
`Spellbreak-v1.2.1.dmg` and the stable `Spellbreak.dmg` the buy link downloads.

Selling today: A$29 once, unlocked, from spellbreak.app (Square checkout).

Open: the Mac App Store lane (needs Apple Distribution + Mac Installer
Distribution identities and `Spellbreak_MAS.provisionprofile`), a real-device
audio pass, and the icon identity, which is Pablo's call.

### Verify before repeating any of this

```bash
./release-check.sh                          # 19 gates over the DMG in dist/
dmg-doctor dist/Spellbreak-v1.2.0.dmg       # mount/sign/notarize/spctl, on any copy
spctl -a -vvv -t open --context context:primary-signature dist/Spellbreak-v1.2.0.dmg
gh release list -R pibulus/spellbreak --limit 3
bash scripts/screen-busy-check.sh           # ScreenBusy heuristic, no app needed
```

A green release check says the artifact is good. It says nothing about the site,
and a live site says nothing about commerce — curl the checkout before claiming
it works.

---

## Where the truth lives

Docs drift silently. When this file and the code disagree, the code wins, then
fix this file.

| Fact | Authority |
| --- | --- |
| Break length / interval options, defaults | `PreferencesView.swift` (`GradientSlider` options) |
| Hold-to-skip duration | `OverlayWindow.swift` (`requiredHoldDuration`) |
| Lock mode behaviour | `OverlayWindow.swift` (skip ring gated on `lockMode`) |
| Pause rules (busy, away, sleep) | `SpellbreakApp.swift` (`shouldHoldBreak()`) + `Utilities.swift` (`ScreenBusy`) |
| Break messages | `SpellTextGenerator.swift` |
| Palettes and themes | `AuroraBackground.swift` (`AuroraPalette`) |
| Trial and unlock | `Store.swift` (`-DAPP_STORE` builds only) |
| Price, store copy | `APP_STORE.md`, `APP_STORE_SUBMISSION.md` |
| What the site promises | `spellbreak-site/routes/` — not this file |

---

## Repo map

```
Sources/Spellbreak/
├── SpellbreakApp.swift        entry, AppState, overlay + mirror controllers, pause logic
├── OverlayWindow.swift        the break itself: waves, message, hold-to-skip ring
├── BreakCountdownWindow.swift floating heads-up pill before a break lands
├── AuroraBackground.swift     Canvas + TimelineView waves, AuroraPalette
├── AmbientParticles.swift     floating orbs, palette-matched
├── SpellTextGenerator.swift   observational message engine
├── PreferencesView.swift      Time / Vibes / About tabs
├── MenuViewSimple.swift       menu bar popover
├── StatusBarController.swift  menu bar item
├── SoundManager.swift         chimes + ambient, fades, follows output routing
├── Store.swift                App Store trial + unlock (App Store builds only)
├── Utilities.swift            Color/Timer extensions, ScreenBusy heuristic
└── Errors/AppErrors.swift

Tests/                ScreenBusyCheck, SoundManagerCheck (run by scripts/, not XCTest)
scripts/              render-theme-assets.swift, generate-appstore-cards.py, screen-busy-check.sh
screenshots/          rendered marketing art + App Store cards (not screencaptures)
dist/                 release DMGs (git-ignored)
build/                build output (git-ignored)
```

---

## Features, as the code builds them

### The numbers

- **Break length**: 10, 15, 20, 30, 60, 90, 120, 180 **seconds**. Default 20.
  The maximum is 3 minutes — never write "15-minute breaks".
- **Interval**: 15, 20, 25, 30, 45, 60, 90, 120, 180 **minutes**. Default 20.
- **Hold-to-skip**: `actualBreakDuration / 60`, clamped to **2–15 s**. At the
  180 s maximum that is 3 s, so in practice it is 2–3 seconds. The 15 s ceiling
  is unreachable — never quote it.
- **Displays**: the overlay frame unions every `NSScreen`. The interactive break
  lands on the display holding the pointer; the others get quiet mirrors.

### Lock mode — the unskippable option

Off by default. When on, the skip ring is never drawn (`OverlayWindow.swift:147`)
and its reveal is refused (`:375`); Escape only pulses the screen. The break runs
its clock. This is the one setting where a break genuinely cannot be skipped, so
"unskippable" is true of Lock mode and not of the default. Say it that way.

### Smart pauses (`shouldHoldBreak()`)

Under "Pause while busy": full-screen windows, microphone in use, and typing
(waits for quiet keys, 30 s cap). Always: three minutes with no input and
nothing keeping the display awake holds the break and restarts the interval on
return; sleep does the same. Every hold ends or caps out, so breaks cannot stop
forever. Mic detection reads whether an input device is running via Core Audio —
it never captures audio, and macOS never asks for permission. Key detection asks
only for seconds-since-last-keypress via Quartz.

### Message system

Observational, never instructional: body parts as witnesses, patterns as
entities. Lines run **2–7 words**, most 2–4 — there is no hard cap in code, so
don't advertise one.

- Four pools drawn 30 / 30 / 20 / 20: body + state ("Shoulders adrift"), ambient +
  state ("Static cooling"), mystical spark ("Soft geometry"), full observation
  ("The trance gets comfortable").
- Hour-of-day and lunar sparks are appended to the spark pools.
- *Noticing* lines (2+ skips, 2 h+ since a completed break, 4+ breaks unskipped)
  are drawn 35% of the time they apply.
- The last 60 lines are remembered in UserDefaults (`recentBreakMessages`) and
  never re-drawn; noticing lines have a 24-break window of their own.
- `showBreakMessage` hides the line entirely.

### Visuals

Aurora (hour-aware), Ember (warm), Violet (cool), Surprise (rolls a fresh
harmonious 4-stop jewel palette per break).
Time-based palettes: dawn 5–10 am, day 10 am–5 pm, evening 5–9 pm, night 9 pm–5 am.
Waves are Canvas + TimelineView with a 24 px blur; the message fades in over
1.2 s with a soft glow.

### Privacy

Zero network requests, no analytics, no accounts, no camera. `Spellbreak.entitlements`
grants the App Sandbox and nothing else. `PRIVACY.md` is the public statement and
must stay true of the code.

---

## Build, run, release

```bash
./run.sh                 # dev loop
./build-app.sh           # production → build/Spellbreak.app
swift package clean && swift build -c release

./build-dmg.sh           # signed + notarized + stapled → dist/Spellbreak-v<version>.dmg
./release-check.sh       # 19 gates; run before any release
./build-mas.sh           # App Store variant (needs the MAS certs + profile)
```

Release order: `release-check.sh` green → `gh release create vX.Y.Z dist/…` with
**both** the versioned DMG and the stable `Spellbreak.dmg` → download the stable
asset again and `dmg-doctor` it → probe `/api/payment/create` → cancel the probe
payment link in Square.

`releases/latest/download/Spellbreak.dmg` is load-bearing: `/success` downloads
it directly, and Square's receipt names `spellbreak.app/success` on the line
item. Never publish a release without it.

### Marketing art

Rendered, not screencaptured:

```bash
swift scripts/render-theme-assets.swift          # screenshots/*-2880x1800.png
python3 scripts/generate-appstore-cards.py       # screenshots/appstore/*.png
```

Run the card generator second: it consumes the theme renders as backgrounds.
Both pin exact pixel sizes because App Store only accepts 1280x800, 1440x900,
2560x1600 and 2880x1800, and offscreen AppKit rendering silently doubles
everything to the display's backing scale.

---

## App Store lane

Done: privacy policy, listing copy, sandbox entitlements, icon assets, Developer
ID signing, notarization, store cards at all four sizes.

Needed: Apple Distribution + Mac Installer Distribution identities,
`Spellbreak_MAS.provisionprofile`, then `./build-mas.sh` → Transporter →
TestFlight, then the sandbox checklist in `APP_STORE_SUBMISSION.md` §8.

The App Store build carries the trial and the lock (`Store.swift`); the website
build does not. One listing, two builds, one truth about the price — see
`APP_STORE.md` for which offer is live.

---

## House rules

- Sovereign voice: no "you/your", no interrogatives, no imperative nagging in
  microcopy. Observations, not instructions.
- Warm palette only — cream and warm ink, never `#fff` or `#000`.
- Friction should feel ritual-like, not punitive. 80/20 over cleverness.
- Verify before asserting, then fix the doc that lied.

---

*"The trance gets comfortable."*
