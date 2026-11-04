# Spellbreak

Break the digital spell. A menu bar break timer for macOS that interrupts
screen trance with full-screen color fields: enough friction to make skipping
deliberate, never punitive.

## Features

- **Aurora in four moods**: time-aware Aurora (shifts from dawn through day, dusk,
  and night), always-warm Ember, always-cool Violet, or Surprise (rolls a fresh
  harmonious palette each break).
- **Observational messages**: hundreds of short lines tuned to the hour and moon
  that notice skipped breaks without barking orders, or switch off completely.
- **Hold-to-skip**: a 2 to 3 second hold ring leaves a break early, scaled to
  break length.
- **Lock mode**: hides the skip ring so the break runs its full clock on days
  when an easy exit defeats the point.
- **Heads-up countdown pill**: a quiet 15-second floating pill before a break lands.
- **Pause while busy**: waits out calls, full-screen apps, films, presentations,
  and active typing. Time away from the Mac counts as a break.
- **Every display**: the interactive break lands on the display holding the
  pointer while secondary displays dim with matching aurora mirrors.
- **Private by design**: no accounts, no tracking, no network requests, no camera,
  and zero audio capture (Core Audio only reports whether an input device is active).

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel

## Install

Download from [spellbreak.app](https://spellbreak.app), move Spellbreak to
Applications, and launch. A$29 once, unlocked, with no account, trial timer, or
subscription.

The Mac App Store build (free download, 7-day trial, one-time unlock) builds via
`./build-mas.sh` into `dist/Spellbreak-v<version>-mas.pkg` and is verified by
`./mas-check.sh`.

## Build

```bash
./build-app.sh        # production build -> build/Spellbreak.app
open build/Spellbreak.app
```

For a signed and notarized release or Mac App Store `.pkg`, see [`SIGNING_GUIDE.md`](SIGNING_GUIDE.md) and [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md).

## Project layout

```
Sources/Spellbreak/
├── AppDelegate.swift          # launch setup, status item & standard menu shortcuts
├── SpellbreakApp.swift        # entry point, AppState, window controllers
├── OverlayWindow.swift        # full-screen break overlay
├── AuroraBackground.swift     # animated waves + AuroraPalette
├── AmbientParticles.swift     # floating orbs
├── BreakCountdownWindow.swift # heads-up pill before a break
├── SpellTextGenerator.swift   # observational message engine
├── PreferencesView.swift      # Time / Vibes / About settings
├── MenuViewSimple.swift       # menu bar popover
├── StatusBarController.swift
├── SoundManager.swift
├── Store.swift                # App Store trial + one-time unlock (App Store builds only)
└── Utilities.swift            # palette, ScreenBusy heuristic
```

## Other docs

- [`AGENTS.md`](AGENTS.md): project guide, status, repo map, and source of truth
- [`APP_STORE.md`](APP_STORE.md): store listing copy
- [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md): Mac App Store submission walkthrough
- [`SIGNING_GUIDE.md`](SIGNING_GUIDE.md): signing, notarization, and distribution
- [`PRIVACY.md`](PRIVACY.md): privacy policy
- [`GLOSSARY.md`](GLOSSARY.md): code glossary

## License

Copyright © 2025–2026 Pablo Alvarado. All rights reserved.

## Support

[spellbreak.app](https://spellbreak.app) · [pibulus@gmail.com](mailto:pibulus@gmail.com)
